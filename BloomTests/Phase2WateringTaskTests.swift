import XCTest
@testable import Bloom

@MainActor
final class Phase2WateringTaskTests: XCTestCase {
    private func temporaryURL() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
            .appending(path: "garden.json")
    }

    private func storeWithPlant(_ plant: Plant) -> (BloomStore, WateringSchedule) {
        let store = BloomStore(fileURL: temporaryURL())
        _ = store.addPlant(plant)
        return (store, store.schedule(plant.id)!)
    }

    func testWateredRecordsActualEventAndSchedulesFromThatEvent() throws {
        let plant = Plant(name: "Pothos", species: "Epipremnum aureum", asset: "pothos")
        let (store, schedule) = storeWithPlant(plant)
        let now = Date(timeIntervalSince1970: 1_800_000_000)

        let record = try XCTUnwrap(store.completeWateringCheck(for: plant.id, outcome: .watered, soil: .dry, now: now))
        XCTAssertEqual(record.scheduledFor, schedule.nextCheckAt)
        XCTAssertEqual(record.recordedAt, now)
        XCTAssertEqual(record.outcome, .watered)
        XCTAssertEqual(store.lastWatered(for: plant.id), now)
        XCTAssertEqual(try XCTUnwrap(store.schedule(plant.id)?.nextCheckAt).timeIntervalSince1970, now.addingTimeInterval(14 * 86_400).timeIntervalSince1970, accuracy: 1)
    }

    func testCheckedNotWateredDoesNotUpdateLastWateredAndUsesShortFollowUp() throws {
        let plant = Plant(name: "Snake Plant", species: "Dracaena trifasciata", asset: "snake")
        let (store, _) = storeWithPlant(plant)
        let now = Date(timeIntervalSince1970: 1_800_000_000)

        let record = try XCTUnwrap(store.completeWateringCheck(for: plant.id, outcome: .checkedNotWatered, soil: .dry, now: now, followUpDays: 3))
        XCTAssertEqual(record.outcome, .checkedNotWatered)
        XCTAssertNil(store.lastWatered(for: plant.id))
        XCTAssertEqual(try XCTUnwrap(store.schedule(plant.id)?.nextCheckAt).timeIntervalSince1970, now.addingTimeInterval(3 * 86_400).timeIntervalSince1970, accuracy: 1)
    }

    func testHealthyDampCheckUsesProfileInterval() throws {
        let plant = Plant(name: "Monstera", species: "Monstera deliciosa", asset: "monstera")
        let (store, _) = storeWithPlant(plant)
        let now = Date(timeIntervalSince1970: 1_800_000_000)

        _ = try XCTUnwrap(store.completeWateringCheck(for: plant.id, outcome: .checkedNotWatered, soil: .damp, now: now))
        XCTAssertEqual(try XCTUnwrap(store.schedule(plant.id)?.nextCheckAt).timeIntervalSince1970, now.addingTimeInterval(10 * 86_400).timeIntervalSince1970, accuracy: 1)
    }

    func testFollowUpDaysMustStayWithinApprovedBounds() {
        let plant = Plant(name: "Pothos", species: "Epipremnum aureum", asset: "pothos")
        let (store, _) = storeWithPlant(plant)
        XCTAssertNil(store.completeWateringCheck(for: plant.id, outcome: .checkedNotWatered, soil: .dry, followUpDays: 1))
        XCTAssertNil(store.completeWateringCheck(for: plant.id, outcome: .checkedNotWatered, soil: .dry, followUpDays: 6))
    }

    func testNextCheckDateCanBeEditedWithoutCreatingActivity() throws {
        let plant = Plant(name: "Rubber Plant", species: "Ficus elastica", asset: "rubber")
        let (store, schedule) = storeWithPlant(plant)
        let next = schedule.nextCheckAt.addingTimeInterval(5 * 86_400)

        XCTAssertTrue(store.editNextCheck(for: plant.id, date: next, now: schedule.createdAt))
        XCTAssertEqual(store.schedule(plant.id)?.nextCheckAt, next)
        XCTAssertTrue(store.garden.wateringRecords.isEmpty)
    }

    func testDeletingLatestWateringRecordRemovesOnlyThatRecord() throws {
        let plant = Plant(name: "Pothos", species: "Epipremnum aureum", asset: "pothos")
        let (store, _) = storeWithPlant(plant)
        let first = Date(timeIntervalSince1970: 1_800_000_000)
        let second = first.addingTimeInterval(1_000)
        _ = try XCTUnwrap(store.completeWateringCheck(for: plant.id, outcome: .watered, soil: .dry, now: first))
        _ = try XCTUnwrap(store.completeWateringCheck(for: plant.id, outcome: .watered, soil: .dry, now: second))

        XCTAssertTrue(store.deleteLatestWateringRecord(for: plant.id))
        XCTAssertEqual(store.records(for: plant.id).count, 1)
        XCTAssertEqual(store.records(for: plant.id).first?.recordedAt, first)
    }
}
