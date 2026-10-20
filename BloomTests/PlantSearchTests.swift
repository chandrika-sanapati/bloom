import XCTest
@testable import Bloom

@MainActor final class PlantSearchTests: XCTestCase {
    private var calendar: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(secondsFromGMT: 0)!; return c }
    private func date(_ month: Int) -> Date { calendar.date(from: DateComponents(year: 2026, month: month, day: 15))! }
    private var profile: PlantSearchPreferences { PlantSearchPreferences(area: "Berlin", light: .unsure, location: .berlin) }
    func testSeasonBoundariesAndSouthernHemisphere() {
        XCTAssertEqual(PlantSearchEngine.season(for: profile, date: date(12), calendar: calendar), .winter)
        XCTAssertEqual(PlantSearchEngine.season(for: profile, date: date(3), calendar: calendar), .spring)
        XCTAssertEqual(PlantSearchEngine.season(for: profile, date: date(6), calendar: calendar), .summer)
        XCTAssertEqual(PlantSearchEngine.season(for: profile, date: date(9), calendar: calendar), .autumn)
        var south = profile; south.location?.latitude = -33.9
        XCTAssertEqual(PlantSearchEngine.season(for: south, date: date(12), calendar: calendar), .summer)
        XCTAssertEqual(PlantSearchEngine.season(for: south, date: date(6), calendar: calendar), .winter)
        south.location?.climate = .tropical
        XCTAssertEqual(PlantSearchEngine.season(for: south, date: date(6), calendar: calendar), .yearRound)
    }
    func testIndoorLightOutranksClimateAndSeason() {
        var p = profile; p.light = .bright
        let winter = PlantSearchEngine.suggestions(profile: p, plants: [], date: date(12), calendar: calendar)
        XCTAssertEqual(winter.first?.species.light, .indirect)
        p.light = .lower; p.location?.climate = .tropical
        let tropical = PlantSearchEngine.suggestions(profile: p, plants: [], date: date(6), calendar: calendar)
        XCTAssertEqual(tropical.first?.species.asset, "snake")
        XCTAssertTrue(tropical.first?.reason.contains("natural light") == true)
        XCTAssertTrue(tropical.first { $0.species.asset == "monstera" }?.reason.contains("brighter spot") == true)
    }
    func testClimateChangesPicksWithoutInventingTrends() {
        let winter = PlantSearchEngine.suggestions(profile: profile, plants: [], date: date(10), calendar: calendar)
        XCTAssertEqual(winter.first?.species.asset, "snake")
        var humid = profile; humid.location?.climate = .tropical
        let yearRound = PlantSearchEngine.suggestions(profile: humid, plants: [], date: date(10), calendar: calendar)
        XCTAssertEqual(yearRound.first?.species.asset, "monstera")
        XCTAssertTrue(PlantSearchEngine.seasonalNote(humid).contains("wet and dry seasons vary"))
    }
    func testSearchAliasesAndScientificNamesKeepTheWholeCatalog() {
        XCTAssertEqual(PlantSearchEngine.results(query: "  swiss   cheese ").first?.asset, "monstera")
        XCTAssertEqual(PlantSearchEngine.results(query: "DRACAENA TRIFASCIATA").first?.asset, "snake")
        XCTAssertEqual(PlantSearchEngine.results(query: "sansevieria").first?.asset, "snake")
        XCTAssertEqual(PlantSearchEngine.results(query: "ficus élastica").first?.asset, "rubber")
        XCTAssertTrue(PlantSearchEngine.results(query: "Fern").isEmpty)
        XCTAssertEqual(PlantSearchEngine.results(query: "   ").count, 4)
    }
    func testOwnershipUsesSpeciesBeforeNicknameAndKeepsDuplicatesAddable() {
        let snake = PlantSpecies.catalog[0]
        let renamed = Plant(name: "Milo", species: snake.scientific, asset: "")
        let named = Plant(name: "sansevieria", species: "", asset: "")
        let unrelated = Plant(name: "Snake Plant", species: "Ficus elastica", asset: "")
        XCTAssertEqual(PlantSearchEngine.ownedCount(snake, plants: [renamed, named, unrelated]), 2)
        XCTAssertEqual(PlantSearchEngine.suggestions(profile: nil, plants: [renamed]).count, 4)
        XCTAssertNotEqual(PlantSearchEngine.suggestions(profile: nil, plants: [renamed]).first?.species.asset, "snake")
    }
    func testPreferencesAndBoundedRecentQueriesPersistWithoutChangingPlants() throws {
        let dir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appending(path: "garden.json"), store = BloomStore(fileURL: url, managesNotifications: false)
        let plant = Plant(name: "Milo", species: "", asset: "")
        XCTAssertTrue(store.savePlant(plant))
        XCTAssertTrue(store.savePlantSearchPreferences(profile))
        for query in ["a", "One", "Two", "Three", "Four", "Five", "Six", "  TWO  "] { store.rememberPlantSearch(query) }
        XCTAssertEqual(store.recentPlantSearches, ["TWO", "Six", "Five", "Four", "Three"])
        let loaded = BloomStore(fileURL: url, managesNotifications: false)
        XCTAssertEqual(loaded.plantSearchPreferences, profile)
        XCTAssertEqual(loaded.garden.plants, [plant])
        XCTAssertEqual(loaded.recentPlantSearches, store.recentPlantSearches)
        loaded.clearPlantSearches(); XCTAssertTrue(loaded.recentPlantSearches.isEmpty)
        XCTAssertTrue(loaded.savePlantSearchPreferences(nil))
        XCTAssertNil(BloomStore(fileURL: url, managesNotifications: false).plantSearchPreferences)
    }
    func testLegacyGardenAndFailedPreferenceWriteRemainIntact() throws {
        let dir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appending(path: "garden.json")
        let bytes = Data("{\"plants\":[],\"records\":[],\"hasStarted\":true,\"isSample\":false}".utf8)
        try bytes.write(to: url)
        let old = BloomStore(fileURL: url, managesNotifications: false)
        XCTAssertNil(old.plantSearchPreferences); XCTAssertTrue(old.recentPlantSearches.isEmpty)
        XCTAssertEqual(try Data(contentsOf: url), bytes)
        let blocked = dir.appending(path: "blocked"); try Data([1]).write(to: blocked)
        let failed = BloomStore(fileURL: blocked.appending(path: "garden.json"), managesNotifications: false)
        XCTAssertFalse(failed.savePlantSearchPreferences(profile)); XCTAssertNil(failed.plantSearchPreferences)
        failed.rememberPlantSearch("Monstera"); XCTAssertTrue(failed.recentPlantSearches.isEmpty)
    }
    private func data(temperature: Double = 25, humidity: Double = 70, rain: Double = 2) throws -> Data {
        let months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
        func values(_ value: Double) -> [String: Double] { Dictionary(uniqueKeysWithValues: months.map { ($0, value) }) }
        return try JSONSerialization.data(withJSONObject: ["properties": ["parameter": ["T2M": values(temperature), "RH2M": values(humidity), "PRECTOTCORR": values(rain)]]])
    }
    func testClimateDerivesFromCompleteNormalsAndRejectsMissingData() throws {
        let decoder = JSONDecoder()
        XCTAssertEqual(try decoder.decode(ClimateNormalsResponse.self, from: data()).climate, .tropical)
        XCTAssertEqual(try decoder.decode(ClimateNormalsResponse.self, from: data(temperature: 5)).climate, .cool)
        XCTAssertEqual(try decoder.decode(ClimateNormalsResponse.self, from: data(temperature: 28, humidity: 30, rain: 0.1)).climate, .dry)
        XCTAssertEqual(try decoder.decode(ClimateNormalsResponse.self, from: data(temperature: 17)).climate, .mild)
        XCTAssertNil(try decoder.decode(ClimateNormalsResponse.self, from: data(temperature: -999)).climate)
        XCTAssertNil(try decoder.decode(ClimateNormalsResponse.self, from: Data("{\"properties\":{\"parameter\":{}}}".utf8)).climate)
    }
    func testCityParsingDisambiguatesAndStoresOnlyCoarseCoordinates() throws {
        let data = Data("{\"results\":[{\"name\":\"Berlin\",\"country\":\"Germany\",\"latitude\":52.52437,\"longitude\":13.41053},{\"name\":\"Berlin\",\"country\":\"United States\",\"latitude\":41.6,\"longitude\":-72.7}]}".utf8)
        let cities = try JSONDecoder().decode(CitySearchResponse.self, from: data).locations
        XCTAssertEqual(cities.count, 2); XCTAssertNotEqual(cities[0].id, cities[1].id)
        XCTAssertEqual(cities[0].latitude, 52.5); XCTAssertEqual(cities[0].longitude, 13.4)
        XCTAssertNil(cities[0].climate)
        XCTAssertTrue(try JSONDecoder().decode(CitySearchResponse.self, from: Data("{}".utf8)).locations.isEmpty)
    }
    func testMultiplePlantTypesUseEitherPreferenceAndKeepAllPlantsSearchable() {
        var p = PlantSearchPreferences(area: "", light: .unsure, plantTypes: [.bushy, .trailing])
        let picks = PlantSearchEngine.suggestions(profile: p, plants: [])
        let matches = Set(picks.filter(\.matchesTypePreference).map { $0.species.name })
        XCTAssertEqual(matches, ["Rubber Plant", "Pothos"])
        XCTAssertEqual(PlantSearchEngine.results(query: "Monstera").count, 1)
        p.light = .lower
        XCTAssertEqual(PlantSearchEngine.suggestions(profile: p, plants: []).first?.species.name, "Snake Plant")
        XCTAssertEqual(PlantSearchEngine.results(query: "Golden pothos").first?.name, "Pothos")
    }
    func testNoLocationDoesNotReuseLegacyManualClimateOrInventASeason() throws {
        let old = Data("{\"area\":\"Berlin\",\"climate\":\"Warm and humid year-round\",\"hemisphere\":\"Southern\",\"light\":\"Not sure yet\"}".utf8)
        let saved = try JSONDecoder().decode(PlantSearchPreferences.self, from: old)
        XCTAssertEqual(saved.displayArea, "Berlin"); XCTAssertTrue(saved.selectedTypes.isEmpty)
        XCTAssertEqual(PlantSearchEngine.season(for: saved, date: .now), .unknown)
        XCTAssertNil(saved.regionalClimate)
        var equator = PlantSearchPreferences(area: "", light: .bright, location: GrowingLocation(name: "Quito", region: "", country: "Ecuador", latitude: 0, longitude: -78.5))
        XCTAssertEqual(PlantSearchEngine.season(for: equator, date: .now), .unknown)
        equator.location?.climate = .mild
        XCTAssertEqual(PlantSearchEngine.season(for: equator, date: .now), .unknown)
    }
    func testLocationAndMultipleTypesSurviveRelaunchWithoutChangingGarden() throws {
        let dir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appending(path: "garden.json"), store = BloomStore(fileURL: url, managesNotifications: false)
        let plant = Plant(name: "Existing plant", species: "", asset: "")
        XCTAssertTrue(store.savePlant(plant))
        let saved = PlantSearchPreferences(area: "Berlin", light: .bright, location: .berlin, plantTypes: [.bushy, .trailing])
        XCTAssertTrue(store.savePlantSearchPreferences(saved))
        let loaded = BloomStore(fileURL: url, managesNotifications: false)
        XCTAssertEqual(loaded.plantSearchPreferences, saved); XCTAssertEqual(loaded.garden.plants, [plant])
    }
}
