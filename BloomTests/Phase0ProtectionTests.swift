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
        BloomStore(fileURL: url)
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

    func testPlantAndWateringDataSurviveRelaunch() throws {
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = makeStore(at: url)
        let plant = Plant(name: "Pothos", species: "Epipremnum aureum", asset: "pothos", photo: Data([1, 2, 3]))
        let profile = try XCTUnwrap(WateringProfile.forPlant(plant))
        let schedule = WateringSchedule.initial(
            for: plant,
            profile: profile,
            lastWatered: nil,
            now: Date(timeIntervalSince1970: 1_800_000_000),
            reminderHour: 9,
            reminderMinute: 0,
            calendar: .current
        )
        let record = WateringRecord(
            plantID: plant.id,
            scheduledFor: schedule.nextCheckAt,
            recordedAt: Date(timeIntervalSince1970: 1_800_000_100),
            outcome: .checkedNotWatered,
            soil: .damp,
            note: "Checked without watering"
        )

        XCTAssertTrue(store.savePlant(plant))
        XCTAssertTrue(store.commit {
            $0.wateringSchedules = [schedule]
            $0.wateringRecords = [record]
        })

        let reopened = makeStore(at: url)
        XCTAssertEqual(reopened.plant(plant.id), plant)
        XCTAssertEqual(reopened.schedule(plant.id), schedule)
        XCTAssertEqual(reopened.garden.wateringRecords, [record])
    }

    func testFailedWriteLeavesGardenEmptyAndReportsAnError() throws {
        let blocker = temporaryURL()
        defer { try? FileManager.default.removeItem(at: blocker.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: blocker.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("not a directory".utf8).write(to: blocker)

        let store = BloomStore(fileURL: blocker.appending(path: "garden.json"))
        XCTAssertFalse(store.savePlant(Plant(name: "Must not appear", species: "", asset: "")))
        XCTAssertTrue(store.garden.plants.isEmpty)
        XCTAssertNotNil(store.errorMessage)
    }

    func testCorruptGardenFileStartsWithCleanGreenfieldStore() throws {
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("not valid JSON".utf8).write(to: url)

        let store = makeStore(at: url)
        XCTAssertNil(store.errorMessage)
        XCTAssertTrue(store.garden.plants.isEmpty)
        XCTAssertTrue(store.garden.wateringSchedules.isEmpty)
        XCTAssertTrue(store.garden.wateringRecords.isEmpty)
    }
}
