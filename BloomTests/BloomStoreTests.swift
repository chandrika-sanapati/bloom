import XCTest
@testable import Bloom

@MainActor
final class BloomStoreTests: XCTestCase {
    private func temporaryURL() -> URL {
        FileManager.default.temporaryDirectory.appending(path: UUID().uuidString).appending(path: "garden.json")
    }

    func testCareTasksDistinguishOverdueTodayAndUpcoming() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 19, hour: 12))!
        XCTAssertEqual(CareTaskTiming.classify(now.addingTimeInterval(-1), now: now, calendar: calendar), .overdue)
        XCTAssertEqual(CareTaskTiming.classify(now, now: now, calendar: calendar), .today)
        XCTAssertEqual(CareTaskTiming.classify(now.addingTimeInterval(3600), now: now, calendar: calendar), .today)
        XCTAssertEqual(CareTaskTiming.classify(calendar.date(byAdding: .day, value: 1, to: now)!, now: now, calendar: calendar), .upcoming)
    }

    func testCareTasksUseLocalCalendarDayAtMidnight() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 24, hour: 23, minute: 59))!
        let midnight = calendar.date(byAdding: .minute, value: 1, to: now)!
        XCTAssertEqual(CareTaskTiming.classify(midnight, now: now, calendar: calendar), .upcoming)
        XCTAssertEqual(CareTaskTiming.classify(now, now: midnight, calendar: calendar), .overdue)
    }

    func testPlantsPhotosAndHistorySurviveRelaunch() throws {
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = BloomStore(fileURL: url)
        XCTAssertTrue(store.start(sample: false))
        var plant = Plant(name: "Fern", species: "", asset: "", location: "Study")
        plant.photo = Data([1, 2, 3, 4])
        XCTAssertTrue(store.savePlant(plant))
        let record = CareRecord(plantID: plant.id, kind: .check, soil: .unknown, action: .postponed, note: "Will look again later.")
        XCTAssertTrue(store.saveRecord(record))
        let reopened = BloomStore(fileURL: url)
        XCTAssertEqual(reopened.plant(plant.id), plant)
        XCTAssertEqual(reopened.record(record.id), record)
        XCTAssertTrue(reopened.garden.hasStarted)
    }

    func testEditingReplacesRecordAndUndoRestoresPriorValue() {
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = BloomStore(fileURL: url)
        let plant = Plant(name: "Test", species: "", asset: "")
        XCTAssertTrue(store.savePlant(plant))
        let original = CareRecord(plantID: plant.id, kind: .check, soil: .dry, action: .waited)
        XCTAssertTrue(store.saveRecord(original))
        var edited = original; edited.soil = .damp; edited.note = "Corrected my observation."
        XCTAssertTrue(store.saveRecord(edited))
        XCTAssertEqual(store.records(for: plant.id).count, 1)
        XCTAssertEqual(store.latestCheck(for: plant.id)?.soil, .damp)
        XCTAssertTrue(store.saveRecord(original))
        XCTAssertEqual(store.record(original.id), original)
    }

    func testFollowUpStaysLinkedAndDeletingConcernRemovesIt() {
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = BloomStore(fileURL: url)
        let plant = Plant(name: "Test", species: "", asset: "")
        XCTAssertTrue(store.savePlant(plant))
        let change = CareRecord(plantID: plant.id, kind: .change, area: .leaves, observation: "Brown edges")
        let followUp = CareRecord(plantID: plant.id, kind: .followUp, parentID: change.id, outcome: "About the same")
        XCTAssertTrue(store.saveRecord(change)); XCTAssertTrue(store.saveRecord(followUp))
        XCTAssertEqual(store.record(followUp.id)?.parentID, change.id)
        XCTAssertTrue(store.deleteRecord(change.id))
        XCTAssertTrue(store.records(for: plant.id).isEmpty)
    }

    func testFailedSaveDoesNotChangeGarden() throws {
        let blocker = temporaryURL()
        defer { try? FileManager.default.removeItem(at: blocker.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: blocker.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("file, not a directory".utf8).write(to: blocker)
        let store = BloomStore(fileURL: blocker.appending(path: "garden.json"))
        XCTAssertFalse(store.savePlant(Plant(name: "Must not appear", species: "", asset: "")))
        XCTAssertTrue(store.garden.plants.isEmpty)
        XCTAssertNotNil(store.errorMessage)
    }

    func testCorruptFileIsPreserved() throws {
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let corrupt = Data("not valid JSON".utf8)
        try corrupt.write(to: url)
        let store = BloomStore(fileURL: url)
        XCTAssertNotNil(store.errorMessage)
        XCTAssertFalse(store.start(sample: false))
        XCTAssertEqual(try Data(contentsOf: url), corrupt)
    }

    func testUndoWateringRecalculatesLastWateredDate() {
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = BloomStore(fileURL: url)
        let earlier = Date(timeIntervalSince1970: 1000)
        let plant = Plant(name: "Test", species: "", asset: "", lastWatered: earlier)
        XCTAssertTrue(store.savePlant(plant))
        let check = CareRecord(plantID: plant.id, kind: .check, soil: .dry, action: .watered)
        XCTAssertTrue(store.saveRecord(check))
        XCTAssertEqual(store.wateredDate(for: plant), check.date)
        XCTAssertTrue(store.deleteRecord(check.id))
        XCTAssertEqual(store.wateredDate(for: plant), earlier)
    }

    func testLegacySampleUpgradePreservesRecordsAndRunsOnce() throws {
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        var legacy = BloomStore.sampleGarden()
        legacy.sampleRevision = nil
        legacy.plants = Array(legacy.plants.prefix(3))
        legacy.records = Array(legacy.records.prefix(3))
        legacy.records[0].note = "Keep my existing note"
        let original = legacy.records[0]
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(legacy).write(to: url)
        let updated = BloomStore(fileURL: url)
        XCTAssertEqual(updated.garden.plants.count, 5)
        XCTAssertEqual(updated.garden.records.count, 5)
        XCTAssertEqual(updated.record(original.id), original)
        let reopened = BloomStore(fileURL: url)
        XCTAssertEqual(reopened.garden.plants.map(\.id), updated.garden.plants.map(\.id))
        XCTAssertEqual(reopened.garden.records.count, 5)
    }

    func testRealGardenIsNotExpandedWithSampleData() throws {
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let real = Garden(plants: [Plant(name: "My own plant", species: "", asset: "")], hasStarted: true)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(real)
        try data.write(to: url)
        let reopened = BloomStore(fileURL: url)
        XCTAssertEqual(reopened.garden.plants, real.plants)
        XCTAssertTrue(reopened.garden.records.isEmpty)
        XCTAssertEqual(try Data(contentsOf: url), data)
    }

    func testReminderCategorySurvivesRelaunch() {
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = BloomStore(fileURL: url)
        let plant = Plant(name: "Fern", species: "", asset: "", reminder: Date().addingTimeInterval(86400), reminderKind: .observation)
        XCTAssertTrue(store.savePlant(plant))
        XCTAssertEqual(BloomStore(fileURL: url).plant(plant.id)?.reminderKind, .observation)
    }
    func testGuidedSetupSavesLocationPlacementAndStatusTogether() {
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = BloomStore(fileURL: url)
        let plant = Plant(name: "  Balcony plant  ", species: "", asset: "", location: "Balcony")
        XCTAssertTrue(store.addPlant(plant, placement: .outdoor, status: .needsAttention))
        let saved = BloomStore(fileURL: url).plant(plant.id)
        XCTAssertEqual(saved?.name, "Balcony plant")
        XCTAssertEqual(saved?.location, "Balcony")
        XCTAssertEqual(saved?.placement, .outdoor)
        XCTAssertEqual(saved?.initialStatus, .needsAttention)
        XCTAssertTrue(store.garden.records.isEmpty)
    }

    func testIncompleteOrFailedSetupDoesNotAddAPartialPlant() throws {
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = BloomStore(fileURL: url)
        XCTAssertFalse(store.addPlant(Plant(name: "   ", species: "", asset: ""), placement: .indoor, status: nil))
        XCTAssertTrue(store.garden.plants.isEmpty)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("blocked".utf8).write(to: url)
        let failing = BloomStore(fileURL: url.appending(path: "garden.json"))
        XCTAssertFalse(failing.addPlant(Plant(name: "Fern", species: "", asset: ""), placement: .indoor, status: .notSure))
        XCTAssertTrue(failing.garden.plants.isEmpty)
    }

    func testCompletingCareAndUndoRestoreTheMatchingTask() async throws {
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = BloomStore(fileURL: url, managesNotifications: false)
        let plant = Plant(name: "Fern", species: "", asset: "", reminder: Date().addingTimeInterval(86400), reminderKind: .soilCheck)
        XCTAssertTrue(store.savePlant(plant))
        let record = CareRecord(plantID: plant.id, kind: .check, soil: .dry, action: .watered)
        let saved = await store.finishCare(record)
        let receipt = try XCTUnwrap(saved)
        XCTAssertNil(store.plant(plant.id)?.reminder)
        XCTAssertEqual(BloomStore(fileURL: url).record(record.id), record)
        let undone = await store.undoCare(receipt)
        XCTAssertTrue(undone)
        XCTAssertNil(store.record(record.id))
        XCTAssertEqual(BloomStore(fileURL: url).plant(plant.id)?.reminder, plant.reminder)
    }

    func testUnrelatedObservationKeepsSoilTaskAndNewReminderSurvivesUndo() async throws {
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = BloomStore(fileURL: url, managesNotifications: false)
        let plant = Plant(name: "Fern", species: "", asset: "", reminder: Date().addingTimeInterval(86400), reminderKind: .soilCheck)
        XCTAssertTrue(store.savePlant(plant))
        let change = CareRecord(plantID: plant.id, kind: .change, area: .leaves, observation: "Brown edges")
        let savedChange = await store.finishCare(change)
        XCTAssertFalse(try XCTUnwrap(savedChange).completedReminder)
        XCTAssertEqual(store.plant(plant.id)?.reminder, plant.reminder)
        let check = CareRecord(plantID: plant.id, kind: .check, soil: .dry, action: .waited)
        let savedCheck = await store.finishCare(check)
        let receipt = try XCTUnwrap(savedCheck)
        let next = Date().addingTimeInterval(172800)
        let message = await store.setReminder(for: plant.id, date: next, kind: .observation)
        XCTAssertNil(message)
        let undone = await store.undoCare(receipt)
        XCTAssertTrue(undone)
        XCTAssertEqual(store.plant(plant.id)?.reminder, next)
        XCTAssertEqual(store.plant(plant.id)?.reminderKind, .observation)
        let invalid = await store.setReminder(for: plant.id, date: Date().addingTimeInterval(-1))
        XCTAssertNotNil(invalid)
        XCTAssertEqual(store.plant(plant.id)?.reminder, next)
    }

}
