import XCTest
@testable import Bloom

final class GrowingLocationTests: XCTestCase {
    func testLegacyPlantSearchProfileSchemaStillDecodes() throws {
        let data = Data("""
        {"area":"Berlin","climate":"Cool or cold winters","hemisphere":"Northern","light":"Lower natural light","location":{"name":"Berlin","region":"Berlin","country":"Germany","latitude":52.5,"longitude":13.4,"climate":"Cool or cold winters"},"plantTypes":["Trailing"]}
        """.utf8)
        let profile = try JSONDecoder().decode(PlantSearchPreferences.self, from: data)
        XCTAssertEqual(profile.area, "Berlin")
        XCTAssertEqual(profile.location?.name, "Berlin")
        XCTAssertEqual(profile.plantTypes, [.trailing])
    }
}
