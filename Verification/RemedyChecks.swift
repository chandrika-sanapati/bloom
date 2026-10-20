import Foundation

@main struct RemedyChecks {
    @MainActor static func main() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "BloomRemedyChecks-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        var passed = 0
        func check(_ condition: @autoclosure () -> Bool, _ message: String) { precondition(condition(), message) }
        func pass(_ message: String) { passed += 1; print("PASS: \(message)") }
        let answers = PestAssessment(signs: .cotton, location: .joints, extent: .few, placement: .indoor)
        check(answers.recommendation == .mealybugs, "Supported evidence should offer mealybug plan")
        for signs in PestSigns.allCases where signs != .cotton {
            var uncertain = answers; uncertain.signs = signs
            check(uncertain.recommendation == .inspection, "Other signs must not receive a mealybug treatment")
        }
        var outside = answers; outside.placement = .outdoor; check(outside.recommendation == .inspection, "Indoor scope")
        var severe = answers; severe.extent = .widespread; check(severe.recommendation == .expert, "Heavy damage needs help")
        check(PestAssessment().recommendation == .inspection, "Missing evidence remains uncertain")
        pass("supported, uncertain, outdoor, and widespread evidence take distinct routes")
        let url = root.appending(path: "garden.json"), now = Date()
        let store = BloomStore(fileURL: url, managesNotifications: false)
        let plant = Plant(name: "Test Monstera", species: "", asset: "", reminder: now.addingTimeInterval(86400), reminderKind: .soilCheck)
        check(store.savePlant(plant), "Save fixture")
        let baseline = CareRecord(plantID: plant.id, kind: .change, area: .pests, observation: "Cottony clusters", photo: Data([1,2,3]))
        check(store.saveRecord(baseline), "Save original evidence")
        let second = CareRecord(plantID: plant.id, kind: .change, area: .leaves, observation: "Other change")
        check(store.saveRecord(second), "Save independent case")
        guard let id = store.startCarePlan(observationID: baseline.id, answers: answers, reviewDays: 7, now: now),
              let other = store.startCarePlan(observationID: second.id, answers: PestAssessment(signs: .unsure, location: .unsure, extent: .unsure, placement: .indoor), reviewDays: 3, now: now) else { fatalError("Plan start") }
        check(store.garden.records.count == 2, "Acceptance must not log performed treatment")
        check(store.plant(plant.id)?.reminder == plant.reminder, "Existing soil reminder survives")
        check(store.startCarePlan(observationID: baseline.id, answers: answers, reviewDays: 7) == id && store.carePlans.count == 2, "Repeated acceptance is idempotent")
        let planTasks = store.tasks(for: id), first = planTasks[0], last = planTasks[1], review = planTasks[2]
        check(review.status == .waiting && review.due == nil, "No review clock before actions")
        pass("plans and independent tasks coexist with ordinary reminders without logging unperformed work")
        guard let firstReceipt = store.finishPlanAction(taskID: first.id, now: now.addingTimeInterval(3600)) else { fatalError("First action") }
        check(store.careTask(review.id)?.due == nil, "Review waits for remaining action")
        check(store.finishPlanAction(taskID: first.id) == nil, "No duplicate completion")
        let finished = now.addingTimeInterval(7200)
        guard let lastReceipt = store.finishPlanAction(taskID: last.id, now: finished) else { fatalError("Last action") }
        check(store.careTask(review.id)?.due == Calendar.current.date(byAdding: .day, value: 7, to: finished), "Interval starts at actual final action")
        check(store.careTask(review.id)?.status == .pending, "Follow-up now scheduled")
        check(store.tasks(for: other).contains { $0.status == .waiting }, "Other case unaffected")
        pass("completion is idempotent and follow-up timing uses actual completed actions")
        let manualDate = finished.addingTimeInterval(864000)
        check(store.reschedulePlanTask(review.id, date: manualDate), "Choose custom date")
        check(store.undoPlanTask(lastReceipt), "Undo action")
        check(store.careTask(last.id)?.status == .pending && store.record(lastReceipt.recordID) == nil, "Undo removes performed-care record")
        check(store.careTask(review.id)?.due == manualDate, "Undo preserves explicit review date")
        check(store.undoPlanTask(firstReceipt), "Undo first action")
        pass("Undo restores action state, removes its activity, and preserves a newer chosen review date")
        check(store.finishPlanAction(taskID: first.id, now: now) != nil, "Re-complete first")
        check(store.finishPlanAction(taskID: last.id, now: finished) != nil, "Re-complete last")
        guard let receipt = store.finishPlanReview(taskID: review.id, outcome: .worse, note: "New damage", photo: Data([4,5]), now: finished.addingTimeInterval(60)) else { fatalError("Review") }
        check(store.carePlan(id)?.status == .needsReview, "Worse results require reassessment")
        check(!store.closePlan(id, resolved: true), "Worse result must not resolve case")
        check(store.record(receipt.recordID)?.parentID == baseline.id && store.record(receipt.recordID)?.planID == id, "Review linked to exact baseline and plan")
        check(store.undoPlanTask(receipt), "Undo comparison")
        check(store.record(receipt.recordID) == nil && store.careTask(review.id)?.status == .pending, "Comparison undone atomically")
        pass("comparisons link to the exact issue, preserve photos, and require explicit resolution")
        let disk = BloomStore(fileURL: url, managesNotifications: false)
        check(disk.carePlans == store.carePlans && disk.careTasks == store.careTasks, "New state survives relaunch")
        check(disk.carePlan(id)?.baseline.photo == baseline.photo && disk.plant(plant.id)?.reminder == plant.reminder, "Original photo and ordinary reminder preserved")
        pass("plans, task status, baseline photos, and old reminders survive relaunch")
        guard let replacement = store.startCarePlan(observationID: baseline.id, answers: severe, reviewDays: nil, replacing: id, now: finished.addingTimeInterval(120)) else { fatalError("Reassessment") }
        check(store.carePlan(id)?.status == .stopped && store.tasks(for: id).allSatisfy { !$0.isOpen }, "Reassessment closes only old pending work")
        check(store.planIsOpen(replacement) && store.planIsOpen(other), "Other issue stays open")
        check(store.deleteRecord(baseline.id), "Delete exact concern")
        check(store.carePlan(id) == nil && store.carePlan(replacement) == nil && store.carePlan(other) != nil, "Cascade retains independent concern")
        check(store.garden.records.allSatisfy { $0.parentID != baseline.id }, "No orphan actions or follow-ups")
        pass("reassessment and deletion affect only the relevant issue and its tasks")
        let simple = store.tasks(for: other).first { $0.step != .review }!
        check(store.finishPlanAction(taskID: simple.id, skipped: true) != nil, "Skip without completion")
        check(store.carePlan(other)?.status == .needsReview && store.tasks(for: other).first { $0.step == .review }?.due == nil, "Skipping every action starts no outcome timer")
        pass("skipped actions are distinct from completed treatment and do not start a false recovery clock")
        var old = Garden(plants: [plant], records: [baseline], hasStarted: true)
        old.carePlans = nil; old.careTasks = nil
        let oldURL = root.appending(path: "old.json"), oldBytes = try JSONEncoder().encode(old)
        try oldBytes.write(to: oldURL)
        let oldStore = BloomStore(fileURL: oldURL, managesNotifications: false)
        check(oldStore.carePlans.isEmpty && oldStore.careTasks.isEmpty && oldStore.garden.records == [baseline], "Old garden decodes")
        let reopenedBytes = try Data(contentsOf: oldURL)
        check(reopenedBytes == oldBytes, "Opening old garden doesn't rewrite it")
        pass("older gardens open without migration, seeding, or rewriting their saved bytes")
        let blockDir = root.appending(path: "blocked"), failing = BloomStore(fileURL: blockDir.appending(path: "garden.json"), managesNotifications: false)
        check(failing.savePlant(plant) && failing.saveRecord(baseline), "Failure fixture")
        try FileManager.default.removeItem(at: blockDir); try Data("blocker".utf8).write(to: blockDir)
        check(failing.startCarePlan(observationID: baseline.id, answers: answers, reviewDays: 7) == nil && failing.carePlans.isEmpty && failing.careTasks.isEmpty, "Failed plan writes leave no partial state")
        pass("failed plan persistence leaves both plans and tasks unchanged")
        print("\(passed) remedy checks passed.")
    }
}
