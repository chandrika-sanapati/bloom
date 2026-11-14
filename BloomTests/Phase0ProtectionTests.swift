import XCTest
@testable import Bloom

@MainActor
final class Phase0ProtectionTests: XCTestCase {
    private func temporaryURL() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
            .appending(path: "garden.json")
    }

    private func makeStore(at url: URL) -> BloomStore {
        BloomStore(fileURL: url, managesNotifications: false)
    }

    func testCatalogContainsOnlyTheFourSupportedMVPPlants() {
        XCTAssertEqual(PlantSpecies.catalog.map(\.name), ["Snake Plant", "Monstera", "Rubber Plant", "Pothos"])
        XCTAssertEqual(PlantSpecies.catalog.map(\.scientific), [
            "Dracaena trifasciata",
            "Monstera deliciosa",
            "Ficus elastica",
            "Epipremnum aureum"
        ])
    }

    func testCustomPlantPersistsWithoutAnInventedAutomaticSchedule() throws {
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = makeStore(at: url)
        let custom = Plant(name: "My unknown plant", species: "", asset: "")

        XCTAssertTrue(store.addPlant(custom, status: nil))
        let saved = try XCTUnwrap(store.plant(custom.id))
        XCTAssertNil(saved.reminder)
        XCTAssertNil(saved.reminderKind)

        let reopened = makeStore(at: url)
        XCTAssertEqual(reopened.plant(custom.id), saved)
    }

    func testSupportedPlantAndCareHistorySurviveRelaunch() throws {
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = makeStore(at: url)
        let plant = Plant(name: "Pothos", species: "Epipremnum aureum", asset: "pothos", photo: Data([1, 2, 3]))
        let record = CareRecord(plantID: plant.id, kind: .check, soil: .damp, action: .waited, note: "Checked without watering")

        XCTAssertTrue(store.savePlant(plant))
        XCTAssertTrue(store.saveRecord(record))

        let reopened = makeStore(at: url)
        XCTAssertEqual(reopened.plant(plant.id), plant)
        XCTAssertEqual(reopened.record(record.id), record)
    }

    func testLegacyObservationReminderAndCareDataRemainDecodable() throws {
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let plantID = UUID()
        let recordID = UUID()
        let legacyRecord = CareRecord(
            id: recordID,
            plantID: plantID,
            date: Date(timeIntervalSince1970: 1_800_000_000),
            kind: .change,
            area: .leaves,
            observation: "Dropping leaves"
        )
        let encodedRecord = try JSONEncoder().encode(legacyRecord)
        let recordObject = try XCTUnwrap(JSONSerialization.jsonObject(with: encodedRecord) as? [String: Any])
        let legacyObject: [String: Any] = [
            "plants": [[
                "id": plantID.uuidString,
                "name": "Snake Plant",
                "species": "Dracaena trifasciata",
                "asset": "snake",
                "reminder": 1_800_000_000,
                "reminderKind": "observation",
                "reminderObservationID": recordID.uuidString
            ]],
            "records": [recordObject],
            "hasStarted": true,
            "isSample": false
        ]
        let legacyJSON = try JSONSerialization.data(withJSONObject: legacyObject)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try legacyJSON.write(to: url)

        let store = makeStore(at: url)
        XCTAssertEqual(store.plant(plantID)?.reminderKind, .observation)
        XCTAssertEqual(store.plant(plantID)?.reminderObservationID, recordID)
        XCTAssertEqual(store.record(recordID)?.kind, .change)
        XCTAssertNil(store.errorMessage)
    }

    func testFailedWriteLeavesGardenEmptyAndReportsAnError() throws {
        let blocker = temporaryURL()
        defer { try? FileManager.default.removeItem(at: blocker.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: blocker.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("not a directory".utf8).write(to: blocker)

        let store = BloomStore(fileURL: blocker.appending(path: "garden.json"), managesNotifications: false)
        XCTAssertFalse(store.savePlant(Plant(name: "Must not appear", species: "", asset: "")))
        XCTAssertTrue(store.garden.plants.isEmpty)
        XCTAssertNotNil(store.errorMessage)
    }

    func testCorruptGardenFileIsPreservedAndCannotBeStarted() throws {
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let corrupt = Data("not valid JSON".utf8)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try corrupt.write(to: url)

        let store = makeStore(at: url)
        XCTAssertNotNil(store.errorMessage)
        XCTAssertFalse(store.start(sample: false))
        XCTAssertEqual(try Data(contentsOf: url), corrupt)
    }
}
