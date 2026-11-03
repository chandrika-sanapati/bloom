import XCTest
@testable import Bloom

final class PlantSearchTests: XCTestCase {
    func testSearchMatchesCommonScientificAndAliasNames() {
        XCTAssertEqual(PlantSearchEngine.results(query: "  swiss   cheese ").first?.asset, "monstera")
        XCTAssertEqual(PlantSearchEngine.results(query: "DRACAENA TRIFASCIATA").first?.asset, "snake")
        XCTAssertEqual(PlantSearchEngine.results(query: "sansevieria").first?.asset, "snake")
        XCTAssertEqual(PlantSearchEngine.results(query: "ficus élastica").first?.asset, "rubber")
        XCTAssertTrue(PlantSearchEngine.results(query: "Fern").isEmpty)
        XCTAssertEqual(PlantSearchEngine.results(query: "   ").count, 4)
    }

    @MainActor func testLegacyDiscoveryProfileIsPreservedWithoutActivatingIt() throws {
        let id = UUID()
        let data = Data("""
        {"plants":[{"id":"\(id.uuidString)","name":"Snake Plant","species":"Dracaena trifasciata","asset":"snake"}],"records":[],"hasStarted":true,"isSample":false,"plantSearchPreferences":{"area":"Berlin","light":"Lower natural light","location":{"name":"Berlin","region":"Berlin","country":"Germany","latitude":52.5,"longitude":13.4,"climate":"Cool or cold winters"},"plantTypes":["Trailing"]}}
        """.utf8)
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: "garden.json")
        try data.write(to: url)

        let store = BloomStore(fileURL: url, managesNotifications: false)
        XCTAssertEqual(store.plant(id)?.displayName, "Snake Plant")
        XCTAssertEqual(store.garden.plants.count, 1)
        XCTAssertEqual(try Data(contentsOf: url), data)
        let savedJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        XCTAssertNotNil(savedJSON["plantSearchPreferences"])
        XCTAssertNil(store.errorMessage)
    }
}
