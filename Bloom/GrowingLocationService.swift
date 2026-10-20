import Foundation
import CoreLocation
import MapKit
import Observation

struct GrowingLocationService {
    var session: URLSession = .shared
    var usesFixtures = ProcessInfo.processInfo.arguments.contains("--uitesting")
    func search(_ query: String) async throws -> [GrowingLocation] {
        let clean = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard clean.count >= 2 else { return [] }
        if usesFixtures {
            if clean.lowercased().contains("berlin") { var city = GrowingLocation.berlin; city.climate = nil; return [city] }
            return []
        }
        var url = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
        url.queryItems = [URLQueryItem(name: "name", value: clean), URLQueryItem(name: "count", value: "6"), URLQueryItem(name: "language", value: Locale.current.language.languageCode?.identifier ?? "en")]
        return try JSONDecoder().decode(CitySearchResponse.self, from: await data(url.url!, timeout: 12)).locations
    }
    func addingClimate(to city: GrowingLocation) async throws -> GrowingLocation {
        guard city.valid else { throw URLError(.badURL) }
        if usesFixtures {
            if ProcessInfo.processInfo.arguments.contains("--uitesting-climate-unavailable") { throw URLError(.notConnectedToInternet) }
            var next = city; next.climate = .cool; return next
        }
        // Use coarse regional coordinates, never a street address or precise GPS fix.
        var url = URLComponents(string: "https://power.larc.nasa.gov/api/temporal/climatology/point")!
        url.queryItems = [URLQueryItem(name: "parameters", value: "T2M,RH2M,PRECTOTCORR"), URLQueryItem(name: "community", value: "AG"),
                          URLQueryItem(name: "latitude", value: String((city.latitude * 2).rounded() / 2)), URLQueryItem(name: "longitude", value: String((city.longitude * 2).rounded() / 2)), URLQueryItem(name: "format", value: "JSON")]
        let response = try JSONDecoder().decode(ClimateNormalsResponse.self, from: await data(url.url!, timeout: 10))
        guard let climate = response.climate else { throw URLError(.cannotParseResponse) }
        var ready = city; ready.climate = climate; return ready
    }
    private func data(_ url: URL, timeout: TimeInterval) async throws -> Data {
        var request = URLRequest(url: url); request.timeoutInterval = timeout
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { throw URLError(.badServerResponse) }
        return data
    }
}

@MainActor @Observable final class PlantLocationLocator: NSObject, @preconcurrency CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @ObservationIgnored private var pending: CheckedContinuation<CLLocation, Error>?
    @ObservationIgnored private var timeout: Task<Void, Never>?
    override init() {
        super.init(); manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    }
    func locate() async throws -> GrowingLocation {
        let fix: CLLocation = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                cancel(); pending = continuation
                timeout = Task { [weak self] in
                    try? await Task.sleep(for: .seconds(15))
                    if !Task.isCancelled { self?.finish(.failure(URLError(.timedOut))) }
                }
                switch manager.authorizationStatus {
                case .authorizedAlways, .authorizedWhenInUse: manager.requestLocation()
                case .notDetermined: manager.requestWhenInUseAuthorization()
                default: finish(.failure(CLError(.denied)))
                }
            }
        } onCancel: { Task { @MainActor in self.cancel() } }
        try Task.checkCancellation()
        let coordinate = fix.coordinate
        let latitude = GrowingLocation.coarse(coordinate.latitude), longitude = GrowingLocation.coarse(coordinate.longitude)
        let coarseFix = CLLocation(latitude: latitude, longitude: longitude)
        if #available(iOS 26.0, *) {
            guard let request = MKReverseGeocodingRequest(location: coarseFix) else { throw URLError(.cannotFindHost) }
            let items = try await withTaskCancellationHandler { try await request.mapItems } onCancel: { request.cancel() }
            guard let address = items.first?.addressRepresentations, let name = address.cityName else { throw URLError(.cannotParseResponse) }
            return GrowingLocation(name: name, region: "", country: address.regionName ?? "", latitude: latitude, longitude: longitude)
        } else {
            let geocoder = CLGeocoder()
            let places = try await geocoder.reverseGeocodeLocation(coarseFix)
            guard let place = places.first, let name = place.locality ?? place.subAdministrativeArea else { throw URLError(.cannotParseResponse) }
            return GrowingLocation(name: name, region: place.administrativeArea ?? "", country: place.country ?? "", latitude: latitude, longitude: longitude)
        }
    }
    func cancel() { finish(.failure(CancellationError())) }
    private func finish(_ result: Result<CLLocation, Error>) {
        timeout?.cancel(); timeout = nil
        manager.stopUpdatingLocation()
        let continuation = pending; pending = nil; continuation?.resume(with: result)
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard pending != nil else { return }
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: manager.requestLocation()
        case .denied, .restricted: finish(.failure(CLError(.denied)))
        default: break
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, location.horizontalAccuracy >= 0, abs(location.timestamp.timeIntervalSinceNow) < 300 else { return }
        finish(.success(location))
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { finish(.failure(error)) }
}
