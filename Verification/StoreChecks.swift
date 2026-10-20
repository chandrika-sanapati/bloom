import Foundation

// Runs the real model on the Mac when an iOS Simulator isn't available.
// Compile together with Models.swift, CarePlanModels.swift, and CarePlanStore.swift. No test doubles or external dependencies.
@main
struct StoreChecks {
    @MainActor static func main() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "BloomChecks-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        var passed = 0
        func check(_ value: @autoclosure () -> Bool, _ message: String) {
            precondition(value(), message)
        }
        let url = root.appending(path: "garden.json")
        let store = BloomStore(fileURL: url, managesNotifications: false)
        check(store.start(sample: false), "Start garden")
        let earlier = Date(timeIntervalSince1970: 1000)
        let plant = Plant(name: "Fern", species: "", asset: "", location: "Study", lastWatered: earlier, photo: Data([1,2,3,4]))
        check(store.savePlant(plant), "Save plant")
        let original = CareRecord(plantID: plant.id, kind: .check, soil: .unknown, action: .postponed, note: "Unsure; checking later.")
        check(store.saveRecord(original), "Save unknown / postponed check")
        let reopened = BloomStore(fileURL: url)
        check(reopened.plant(plant.id) == plant && reopened.record(original.id) == original && reopened.garden.hasStarted, "Relaunch preserves photo, plant, record, and onboarding")
        passed += 1; print("PASS: persistence round-trip, including photos and unknown choices")

        var edited = original; edited.soil = .dry; edited.action = .watered
        check(store.saveRecord(edited), "Edit record")
        check(store.records(for: plant.id).count == 1 && store.wateredDate(for: plant) == edited.date, "Edit must replace existing record")
        check(store.saveRecord(original), "Undo edit")
        check(store.record(original.id) == original && store.wateredDate(for: plant) == earlier, "Undo must restore original record and last-watered date")
        passed += 1; print("PASS: edit and undo preserve record identity and correct watering history")

        let change = CareRecord(plantID: plant.id, kind: .change, area: .leaves, observation: "Brown edges")
        let follow = CareRecord(plantID: plant.id, kind: .followUp, parentID: change.id, outcome: "About the same")
        check(store.saveRecord(change) && store.saveRecord(follow), "Save linked records")
        check(store.record(follow.id)?.parentID == change.id, "Follow-up links to concern")
        check(store.deleteRecord(change.id), "Delete concern")
        check(store.record(follow.id) == nil && store.record(original.id) != nil, "Remove only concern and linked follow-ups")
        passed += 1; print("PASS: follow-up linkage and concern deletion")

        let missing = CareRecord(plantID: UUID(), kind: .check)
        check(!store.saveRecord(missing), "Orphan records must be rejected")
        passed += 1; print("PASS: records cannot reference a missing plant")

        let blocker = root.appending(path: "blocker")
        try Data("not a directory".utf8).write(to: blocker)
        let blocked = BloomStore(fileURL: blocker.appending(path: "garden.json"))
        check(!blocked.savePlant(plant) && blocked.garden.plants.isEmpty && blocked.errorMessage != nil, "Failed writes must not mutate memory")
        passed += 1; print("PASS: failed writes retain original in-memory state and surface an error")

        let corruptURL = root.appending(path: "corrupt.json")
        let corrupt = Data("invalid JSON".utf8)
        try corrupt.write(to: corruptURL)
        let damaged = BloomStore(fileURL: corruptURL)
        check(damaged.errorMessage != nil && !damaged.start(sample: true), "Corrupt files must not be overwritten")
        let preserved = try Data(contentsOf: corruptURL)
        check(preserved == corrupt, "Original corrupt file remains intact")
        passed += 1; print("PASS: corrupt saved data is preserved for recovery")

        check(store.deletePlant(plant.id), "Delete plant")
        let afterDelete = BloomStore(fileURL: url)
        check(afterDelete.garden.plants.isEmpty && afterDelete.garden.records.isEmpty, "Deletion must persist and remove plant's records")
        passed += 1; print("PASS: deleting a plant persists and removes its history")
        let legacyURL = root.appending(path: "legacy-sample.json")
        var legacy = BloomStore.sampleGarden()
        legacy.sampleRevision = nil
        legacy.plants = Array(legacy.plants.prefix(3))
        legacy.records = Array(legacy.records.prefix(3))
        legacy.records[0].note = "Keep this note"
        let kept = legacy.records[0]
        try JSONEncoder().encode(legacy).write(to: legacyURL)
        let upgraded = BloomStore(fileURL: legacyURL)
        check(upgraded.garden.plants.count == 5 && upgraded.garden.records.count == 5, "Legacy demo expands to five plants and five activities")
        check(upgraded.record(kept.id) == kept, "Legacy records are preserved")
        let again = BloomStore(fileURL: legacyURL)
        check(again.garden.plants.map(\.id) == upgraded.garden.plants.map(\.id) && again.garden.records.count == 5, "Sample expansion is idempotent")
        passed += 1; print("PASS: legacy sample expands once and preserves existing records")

        let realURL = root.appending(path: "real.json")
        let real = Garden(plants: [Plant(name: "My plant", species: "", asset: "")], hasStarted: true)
        let realData = try JSONEncoder().encode(real)
        try realData.write(to: realURL)
        let realStore = BloomStore(fileURL: realURL)
        let afterOpen = try Data(contentsOf: realURL)
        check(realStore.garden.plants == real.plants && realStore.garden.records.isEmpty && afterOpen == realData, "Real gardens must not receive sample content")
        passed += 1; print("PASS: real gardens and their saved bytes remain unchanged")

        let reminderPlant = Plant(name: "Fern", species: "", asset: "", reminder: Date().addingTimeInterval(86400), reminderKind: .observation)
        check(store.savePlant(reminderPlant), "Save reminder metadata")
        check(BloomStore(fileURL: url).plant(reminderPlant.id)?.reminderKind == .observation, "Reminder category must survive relaunch")
        passed += 1; print("PASS: reminder categories persist without scheduling test notifications")

        let setupPlant = Plant(name: "  Patio plant  ", species: "", asset: "", location: "Patio")
        check(store.addPlant(setupPlant, placement: .outdoor, status: .needsAttention), "Save guided setup")
        let setupSaved = BloomStore(fileURL: url).plant(setupPlant.id)
        check(setupSaved?.name == "Patio plant" && setupSaved?.location == "Patio" && setupSaved?.placement == .outdoor && setupSaved?.initialStatus == .needsAttention, "Entire setup survives relaunch")
        passed += 1; print("PASS: guided setup persists location, placement, and current status together")
        let countBefore = store.garden.plants.count
        check(!store.addPlant(Plant(name: "  ", species: "", asset: ""), placement: .indoor, status: nil), "Reject empty name")
        check(store.garden.plants.count == countBefore, "No partial plant on validation failure")
        let failedCount = blocked.garden.plants.count
        check(!blocked.addPlant(Plant(name: "Not saved", species: "", asset: ""), placement: .indoor, status: .notSure), "Reject failed setup write")
        check(blocked.garden.plants.count == failedCount, "No partial plant on write failure")
        passed += 1; print("PASS: invalid and failed setup writes do not add partial plants")
        let taskStore = BloomStore(fileURL: root.appending(path: "tasks.json"), managesNotifications: false)
        let due = Date().addingTimeInterval(86400)
        let taskPlant = Plant(name: "Task fern", species: "", asset: "", reminder: due, reminderKind: .soilCheck)
        check(taskStore.savePlant(taskPlant), "Save task plant")
        let completedCheck = CareRecord(plantID: taskPlant.id, kind: .check, soil: .dry, action: .watered)
        guard let receipt = await taskStore.finishCare(completedCheck) else { fatalError("Task save failed") }
        check(taskStore.plant(taskPlant.id)?.reminder == nil && taskStore.record(completedCheck.id) != nil, "Record and task completion are atomic")
        let completedDisk = BloomStore(fileURL: root.appending(path: "tasks.json"), managesNotifications: false)
        check(completedDisk.plant(taskPlant.id)?.reminder == nil && completedDisk.record(completedCheck.id) != nil, "Task completion survives relaunch")
        let undone = await taskStore.undoCare(receipt)
        check(undone && taskStore.record(completedCheck.id) == nil && taskStore.plant(taskPlant.id)?.reminder == due, "Undo restores task and removes saved check")
        passed += 1; print("PASS: care completion and Undo persist the matching reminder and record together")

        let unrelatedChange = CareRecord(plantID: taskPlant.id, kind: .change, area: .leaves, observation: "Brown edges")
        guard let unrelatedReceipt = await taskStore.finishCare(unrelatedChange) else { fatalError("Observation save failed") }
        check(!unrelatedReceipt.completedReminder && taskStore.plant(taskPlant.id)?.reminder == due, "Observation must not clear a soil task")
        let child = CareRecord(plantID: taskPlant.id, kind: .followUp, parentID: unrelatedChange.id, outcome: "About the same")
        check(taskStore.saveRecord(child), "Save linked comparison")
        let undoneChange = await taskStore.undoCare(unrelatedReceipt)
        check(undoneChange && taskStore.record(child.id) == nil, "Undo must not leave orphan follow-ups")
        passed += 1; print("PASS: task categories remain distinct and Undo removes linked follow-ups")

        guard let secondReceipt = await taskStore.finishCare(completedCheck) else { fatalError("Second check failed") }
        let nextDate = due.addingTimeInterval(86400)
        let scheduleMessage = await taskStore.setReminder(for: taskPlant.id, date: nextDate, kind: .observation)
        check(scheduleMessage == nil, "Schedule next task")
        let undoneSecond = await taskStore.undoCare(secondReceipt)
        check(undoneSecond && taskStore.plant(taskPlant.id)?.reminder == nextDate && taskStore.plant(taskPlant.id)?.reminderKind == .observation, "Undo preserves a newly chosen reminder")
        let pastMessage = await taskStore.setReminder(for: taskPlant.id, date: Date().addingTimeInterval(-100))
        check(pastMessage != nil && taskStore.plant(taskPlant.id)?.reminder == nextDate, "Past date rejected without changing reminder")
        passed += 1; print("PASS: new reminders survive Undo and invalid dates leave the task unchanged")

        let failingDirectory = root.appending(path: "failing-tasks")
        let failingTasks = BloomStore(fileURL: failingDirectory.appending(path: "garden.json"), managesNotifications: false)
        check(failingTasks.savePlant(taskPlant), "Prepare persistence failure fixture")
        try FileManager.default.removeItem(at: failingDirectory)
        try Data("blocked".utf8).write(to: failingDirectory)
        let failedReceipt = await failingTasks.finishCare(completedCheck)
        check(failedReceipt == nil && failingTasks.record(completedCheck.id) == nil && failingTasks.plant(taskPlant.id)?.reminder == due, "Failed save retains reminder and does not add activity")
        passed += 1; print("PASS: failed task completion leaves both activity and reminder unchanged")
        print("\(passed) model checks passed.")
    }
}
