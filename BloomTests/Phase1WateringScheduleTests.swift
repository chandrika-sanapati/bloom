import XCTest
@testable import Bloom

@MainActor
final class Phase1WateringScheduleTests: XCTestCase {
    private func temporaryURL() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
            .appending(path: "garden.json")
    }

    func testProfilesExposeTheApprovedRangesAndStartingIntervals() {
        XCTAssertEqual(WateringProfile.supported.map(\.startingIntervalDays), [21, 10, 14, 14])
        XCTAssertEqual(WateringProfile.supported.map { $0.rangeDays.lowerBound }, [14, 7, 7, 7])
        XCTAssertEqual(WateringProfile.supported.map { $0.rangeDays.upperBound }, [30, 14, 21, 21])
    }

    func testAddingSupportedPlantCreatesOneProfileBasedSchedule() throws {
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = BloomStore(fileURL: url)
        let plant = Plant(name: "Pothos", species: "Epipremnum aureum", asset: "pothos")

        XCTAssertTrue(store.addPlant(plant))
        let schedule = try XCTUnwrap(store.schedule(plant.id))
        XCTAssertEqual(schedule.profileID, "Epipremnum aureum")
        XCTAssertEqual(schedule.profileIntervalDays, 14)
        XCTAssertEqual(schedule.profileRange, 7...21)
        XCTAssertEqual(store.garden.wateringSchedules.count, 1)
    }

    func testKnownLastWateredDateDrivesFirstCheck() throws {
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = BloomStore(fileURL: url)
        let plant = Plant(name: "Snake Plant", species: "Dracaena trifasciata", asset: "snake")
        let lastWatered = Date(timeIntervalSince1970: 1_800_000_000)

        XCTAssertTrue(store.savePlant(plant))
        XCTAssertTrue(store.commit { $0.wateringRecords = [WateringRecord(plantID: plant.id, scheduledFor: lastWatered, recordedAt: lastWatered, outcome: .watered, soil: .dry)] })
        XCTAssertTrue(store.ensureWateringSchedule(for: plant.id, now: lastWatered, calendar: Calendar(identifier: .gregorian)))

        let schedule = try XCTUnwrap(store.schedule(plant.id))
        let expected = Calendar.current.date(byAdding: .day, value: 21, to: lastWatered)!
        XCTAssertEqual(schedule.nextCheckAt.timeIntervalSince1970, expected.timeIntervalSince1970, accuracy: 1)
    }

    func testUnknownLastWateredDateCreatesBaselineCheckToday() throws {
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = BloomStore(fileURL: url)
        let plant = Plant(name: "Monstera", species: "Monstera deliciosa", asset: "monstera")
        let now = Date()

        XCTAssertTrue(store.savePlant(plant))
        XCTAssertTrue(store.ensureWateringSchedule(for: plant.id, now: now))
        let schedule = try XCTUnwrap(store.schedule(plant.id))
        XCTAssertTrue(Calendar.current.isDate(schedule.nextCheckAt, inSameDayAs: now))
    }

    func testUnsupportedPlantDoesNotReceiveAutomaticSchedule() {
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = BloomStore(fileURL: url)
        let plant = Plant(name: "Custom plant", species: "", asset: "")

        XCTAssertTrue(store.addPlant(plant))
        XCTAssertNil(store.schedule(plant.id))
    }

    func testTimingClassificationUsesScheduleDate() throws {
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = BloomStore(fileURL: url)
        let plant = Plant(name: "Rubber Plant", species: "Ficus elastica", asset: "rubber")
        XCTAssertTrue(store.addPlant(plant))
        let schedule = try XCTUnwrap(store.schedule(plant.id))
        XCTAssertEqual(store.wateringTiming(for: plant.id, now: schedule.nextCheckAt), .today)
    }
}
