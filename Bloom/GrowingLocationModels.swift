import Foundation

struct GrowingLocation: Codable, Equatable, Identifiable {
    var name: String
    var region: String
    var country: String
    var latitude: Double
    var longitude: Double
    var climate: GrowingClimate?
    var id: String { "\(name)-\(latitude)-\(longitude)" }
    var detail: String { [region, country].filter { !$0.isEmpty && $0 != name }.joined(separator: ", ") }
    var displayName: String { name }
    static let berlin = GrowingLocation(name: "Berlin", region: "Berlin", country: "Germany", latitude: 52.5, longitude: 13.4, climate: .cool)
    static func coarse(_ value: Double) -> Double { (value * 10).rounded() / 10 }
    var valid: Bool { latitude.isFinite && longitude.isFinite && (-90...90).contains(latitude) && (-180...180).contains(longitude) }
}

struct CitySearchResponse: Decodable {
    struct City: Decodable {
        var name: String
        var admin1: String?
        var country: String?
        var latitude: Double
        var longitude: Double
        var location: GrowingLocation {
            GrowingLocation(name: name, region: admin1 ?? "", country: country ?? "", latitude: GrowingLocation.coarse(latitude), longitude: GrowingLocation.coarse(longitude))
        }
    }
    var results: [City]?
    var locations: [GrowingLocation] { (results ?? []).map(\.location).filter(\.valid) }
}

struct ClimateNormalsResponse: Decodable {
    struct Properties: Decodable { var parameter: [String: [String: Double]] }
    var properties: Properties
    var climate: GrowingClimate? {
        let months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
        guard let temperature = properties.parameter["T2M"], let rain = properties.parameter["PRECTOTCORR"], let humidity = properties.parameter["RH2M"],
              months.allSatisfy({ temperature[$0].map { (-90...65).contains($0) } == true && rain[$0].map { (0...1000).contains($0) } == true && humidity[$0].map { (0...100).contains($0) } == true }) else { return nil }
        let minimum = months.compactMap { temperature[$0] }.min()!
        if minimum < 10 { return .cool }
        if minimum >= 18 && months.compactMap({ humidity[$0] }).reduce(0, +) / 12 >= 60 { return .tropical }
        if months.contains(where: { temperature[$0]! >= 24 && rain[$0]! < 1 }) { return .dry }
        return .mild
    }
}

enum PlantFormPreference: String, Codable, CaseIterable, Identifiable {
    case upright = "Upright", bushy = "Bushy", trailing = "Trailing", climbing = "Climbing"
    var id: Self { self }
    var subtitle: String {
        switch self { case .upright: "Tall, structured shapes"; case .bushy: "Full, leafy shapes"; case .trailing: "Hanging stems"; case .climbing: "Growing up a support" }
    }
}
extension PlantSpecies {
    var forms: [PlantFormPreference] {
        switch scientific {
        case "Dracaena trifasciata": [.upright]
        case "Monstera deliciosa": [.climbing]
        case "Ficus elastica": [.upright, .bushy]
        case "Epipremnum aureum": [.trailing, .climbing]
        default: []
        }
    }
}
