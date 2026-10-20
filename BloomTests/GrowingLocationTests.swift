import XCTest
@testable import Bloom

@MainActor final class GrowingLocationLiveTests: XCTestCase {
    func testPublicCitySearchAndClimateLookup() async throws {
        let service = GrowingLocationService(usesFixtures: false)
        let cities = try await service.search("Berlin, Germany")
        let berlin = try XCTUnwrap(cities.first { $0.name == "Berlin" && $0.country == "Germany" })
        let climate = try await service.addingClimate(to: berlin)
        XCTAssertEqual(climate.climate, .cool)
        XCTAssertEqual(climate.latitude, 52.5)
    }
}
