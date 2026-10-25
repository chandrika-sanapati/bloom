import XCTest
@testable import Bloom

@MainActor final class CarePlanTests: XCTestCase {
    private var directory: URL!
    private var url: URL { directory.appending(path: "garden.json") }
    override func setUpWithError() throws { directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString) }
    override func tearDownWithError() throws { try? FileManager.default.removeItem(at: directory) }
    private var answers: PestAssessment { PestAssessment(signs: .cotton, location: .joints, extent: .few, placement: .indoor) }
    private func fixture() throws -> (BloomStore, Plant, CareRecord, UUID) {
        let store = BloomStore(fileURL: url, managesNotifications: false)
        let plant = Plant(name: "Monstera", species: "", asset: "", reminder: Date().addingTimeInterval(86400), reminderKind: .soilCheck)
        XCTAssertTrue(store.savePlant(plant))
        let record = CareRecord(plantID: plant.id, kind: .change, area: .pests, observation: "Cottony clusters", photo: Data([1, 2, 3]))
        XCTAssertTrue(store.saveRecord(record))
        let id = try XCTUnwrap(store.startCarePlan(observationID: record.id, answers: answers, reviewDays: 7))
        return (store, plant, record, id)
    }
    func testOnlySupportedEvidenceGetsMealybugPlan() {
        XCTAssertEqual(answers.recommendation, .mealybugs)
        var other = answers; other.signs = .webbing; XCTAssertEqual(other.recommendation, .inspection)
        other = answers; other.location = .soil; XCTAssertEqual(other.recommendation, .inspection)
        other = answers; other.placement = .outdoor; XCTAssertEqual(other.recommendation, .inspection)
        other = answers; other.extent = .widespread; XCTAssertEqual(other.recommendation, .expert)
        XCTAssertFalse(PestAssessment().complete)
        XCTAssertEqual(PestAssessment().recommendation, .inspection)
    }
    func testStartingPlanIsIdempotentAndDoesNotLogTreatment() throws {
        let (store, plant, record, id) = try fixture()
        XCTAssertEqual(store.garden.records.count, 1)
        XCTAssertEqual(store.tasks(for: id).count, 3)
        XCTAssertEqual(store.tasks(for: id).last?.status, .waiting)
        XCTAssertNil(store.tasks(for: id).last?.due)
        XCTAssertEqual(store.plant(plant.id)?.reminder, plant.reminder)
        XCTAssertEqual(store.startCarePlan(observationID: record.id, answers: answers, reviewDays: 7), id)
        XCTAssertEqual(store.carePlans.count, 1)
    }
    func testReviewUsesActualLastCompletedAction() throws {
        let (store, _, _, id) = try fixture()
        let tasks = store.tasks(for: id), now = Date()
        XCTAssertNotNil(store.finishPlanAction(taskID: tasks[0].id, now: now))
        XCTAssertNil(store.careTask(tasks[2].id)?.due)
        let done = now.addingTimeInterval(600)
        XCTAssertNotNil(store.finishPlanAction(taskID: tasks[1].id, now: done))
        XCTAssertEqual(store.careTask(tasks[2].id)?.due, Calendar.current.date(byAdding: .day, value: 7, to: done))
        XCTAssertNil(store.finishPlanAction(taskID: tasks[1].id))
    }
    func testUndoActionPreservesCustomReviewAndOtherReminders() throws {
        let (store, plant, _, id) = try fixture()
        let tasks = store.tasks(for: id)
        XCTAssertNotNil(store.finishPlanAction(taskID: tasks[0].id))
        let receipt = try XCTUnwrap(store.finishPlanAction(taskID: tasks[1].id))
        let custom = Date().addingTimeInterval(864000)
        XCTAssertTrue(store.reschedulePlanTask(tasks[2].id, date: custom))
        XCTAssertTrue(store.undoPlanTask(receipt))
        XCTAssertEqual(store.careTask(tasks[1].id)?.status, .pending)
        XCTAssertNil(store.record(receipt.recordID))
        XCTAssertEqual(store.careTask(tasks[2].id)?.due, custom)
        XCTAssertEqual(store.plant(plant.id)?.reminder, plant.reminder)
    }
    func testSkippingEveryActionStartsNoRecoveryTimer() throws {
        let (store, _, _, id) = try fixture()
        let tasks = store.tasks(for: id)
        XCTAssertNotNil(store.finishPlanAction(taskID: tasks[0].id, skipped: true))
        XCTAssertNotNil(store.finishPlanAction(taskID: tasks[1].id, skipped: true))
        XCTAssertNil(store.careTask(tasks[2].id)?.due)
        XCTAssertEqual(store.carePlan(id)?.status, .needsReview)
        XCTAssertEqual(store.garden.records.filter { $0.kind == .careAction && $0.outcome == "Skipped" }.count, 2)
    }
    func testReviewDoesNotAutomaticallyResolveAndCanBeUndone() throws {
        let (store, _, baseline, id) = try fixture()
        let tasks = store.tasks(for: id)
        for action in tasks where action.step != .review { XCTAssertNotNil(store.finishPlanAction(taskID: action.id)) }
        let receipt = try XCTUnwrap(store.finishPlanReview(taskID: tasks[2].id, outcome: .none, note: "No clusters", photo: Data([4, 5])))
        XCTAssertEqual(store.carePlan(id)?.status, .active)
        XCTAssertEqual(store.record(receipt.recordID)?.parentID, baseline.id)
        XCTAssertEqual(store.record(receipt.recordID)?.photo, Data([4, 5]))
        XCTAssertTrue(store.undoPlanTask(receipt))
        XCTAssertEqual(store.careTask(tasks[2].id)?.status, .pending)
        XCTAssertNil(store.record(receipt.recordID))
    }
    func testExplicitResolutionCancelsPendingTasks() throws {
        let (store, _, _, id) = try fixture()
        let tasks = store.tasks(for: id)
        for action in tasks where action.step != .review { XCTAssertNotNil(store.finishPlanAction(taskID: action.id)) }
        XCTAssertFalse(store.closePlan(id, resolved: true))
        XCTAssertNotNil(store.finishPlanReview(taskID: tasks[2].id, outcome: .none, note: ""))
        XCTAssertTrue(store.schedulePlanReview(id, date: Date().addingTimeInterval(86400)))
        XCTAssertTrue(store.closePlan(id, resolved: true))
        XCTAssertEqual(store.carePlan(id)?.status, .resolved)
        XCTAssertTrue(store.tasks(for: id).allSatisfy { !$0.isOpen })
    }
    func testWorseResultRequiresReassessmentWithoutStrongerAutomaticTreatment() throws {
        let (store, _, record, id) = try fixture()
        let tasks = store.tasks(for: id)
        for action in tasks where action.step != .review { XCTAssertNotNil(store.finishPlanAction(taskID: action.id)) }
        XCTAssertNotNil(store.finishPlanReview(taskID: tasks[2].id, outcome: .worse, note: "Spreading"))
        XCTAssertEqual(store.carePlan(id)?.status, .needsReview)
        XCTAssertEqual(store.tasks(for: id).count, 3)
        var heavy = answers; heavy.extent = .widespread
        let revised = try XCTUnwrap(store.startCarePlan(observationID: record.id, answers: heavy, reviewDays: nil, replacing: id))
        XCTAssertEqual(store.carePlan(id)?.status, .stopped)
        XCTAssertEqual(store.carePlan(revised)?.kind, .expert)
        XCTAssertTrue(store.tasks(for: id).allSatisfy { !$0.isOpen })
    }
    func testPlansPersistAndObservationDeletionHasNoOrphans() throws {
        let (store, plant, record, id) = try fixture()
        XCTAssertNotNil(store.finishPlanAction(taskID: store.tasks(for: id)[0].id))
        let reloaded = BloomStore(fileURL: url, managesNotifications: false)
        XCTAssertEqual(reloaded.carePlans, store.carePlans)
        XCTAssertEqual(reloaded.careTasks, store.careTasks)
        XCTAssertEqual(reloaded.carePlan(id)?.baseline.photo, record.photo)
        XCTAssertTrue(reloaded.deleteRecord(record.id))
        XCTAssertTrue(reloaded.carePlans.isEmpty && reloaded.careTasks.isEmpty && reloaded.garden.records.isEmpty)
        XCTAssertEqual(reloaded.plant(plant.id)?.reminder, plant.reminder)
    }
    func testSeparateIssuesAndOptionalFollowUpCoexist() throws {
        let (store, plant, _, id) = try fixture()
        let second = CareRecord(plantID: plant.id, kind: .change, area: .leaves, observation: "A separate issue")
        XCTAssertTrue(store.saveRecord(second))
        let other = try XCTUnwrap(store.startCarePlan(observationID: second.id, answers: answers, reviewDays: nil))
        XCTAssertEqual(store.tasks(for: other).count, 2)
        XCTAssertTrue(store.closePlan(id, resolved: false))
        XCTAssertTrue(store.tasks(for: other).allSatisfy { $0.status == .pending })
        XCTAssertEqual(store.carePlan(other)?.status, .active)
        XCTAssertFalse(store.reschedulePlanTask(store.tasks(for: other)[0].id, date: .distantPast))
    }
    func testEarlyCheckInKeepsAutomaticReviewAndBackdatedActionUndo() throws {
        let (store, _, _, id) = try fixture()
        let tasks = store.tasks(for: id), now = Date()
        XCTAssertNotNil(store.finishPlanAction(taskID: tasks[0].id, now: now.addingTimeInterval(-3600)))
        let early = try XCTUnwrap(store.reviewPlanNow(id))
        XCTAssertNotEqual(early, tasks[2].id)
        XCTAssertNotNil(store.finishPlanReview(taskID: early, outcome: .same, note: "Early comparison"))
        let last = try XCTUnwrap(store.finishPlanAction(taskID: tasks[1].id, now: now.addingTimeInterval(-600)))
        XCTAssertEqual(store.careTask(tasks[2].id)?.status, .pending)
        XCTAssertTrue(store.canUndoPlanTask(last))
        XCTAssertTrue(store.undoPlanTask(last))
        XCTAssertEqual(store.careTask(tasks[2].id)?.status, .waiting)
    }
    func testObservationReminderStaysWithOriginalIssue() async throws {
        let store = BloomStore(fileURL: url, managesNotifications: false)
        let plant = Plant(name: "Fern", species: "", asset: "")
        XCTAssertTrue(store.savePlant(plant))
        let original = CareRecord(plantID: plant.id, kind: .change, area: .leaves, observation: "Brown edge")
        XCTAssertTrue(store.saveRecord(original))
        let message = await store.setReminder(for: plant.id, date: Date().addingTimeInterval(86400), kind: .observation, observationID: original.id)
        XCTAssertNil(message)
        let newer = CareRecord(plantID: plant.id, kind: .change, area: .pests, observation: "New insects")
        let newerReceipt = await store.finishCare(newer)
        XCTAssertNotNil(newerReceipt)
        XCTAssertEqual(store.plant(plant.id)?.reminderObservationID, original.id)
        let unrelated = await store.finishCare(CareRecord(plantID: plant.id, kind: .followUp, parentID: newer.id, outcome: "About the same"))
        XCTAssertFalse(try XCTUnwrap(unrelated).completedReminder)
        let matching = await store.finishCare(CareRecord(plantID: plant.id, kind: .followUp, parentID: original.id, outcome: "About the same"))
        XCTAssertTrue(try XCTUnwrap(matching).completedReminder)
    }
    func testNewObservationDoesNotCompleteAnEarlierObservationReminder() async throws {
        let store = BloomStore(fileURL: url, managesNotifications: false)
        let plant = Plant(name: "Fern", species: "", asset: "", reminder: Date().addingTimeInterval(86400), reminderKind: .observation)
        XCTAssertTrue(store.savePlant(plant))
        let receipt = await store.finishCare(CareRecord(plantID: plant.id, kind: .change, area: .pests, observation: "New issue"))
        XCTAssertFalse(try XCTUnwrap(receipt).completedReminder)
        XCTAssertEqual(store.plant(plant.id)?.reminder, plant.reminder)
    }
    func testOptionalPestChecksStillCreateConservativeTasksAndPrioritizeHeavyDamage() throws {
        let (store, plant, _, _) = try fixture()
        let observation = CareRecord(plantID: plant.id, kind: .change, area: .pests, observation: "Visible insects")
        XCTAssertTrue(store.saveRecord(observation))
        let unknown = PestAssessment()
        let id = try XCTUnwrap(store.startCarePlan(observationID: observation.id, answers: unknown, reviewDays: nil))
        XCTAssertEqual(store.carePlan(id)?.kind, .inspection)
        XCTAssertEqual(store.carePlan(id)?.assessment, unknown)
        XCTAssertEqual(store.tasks(for: id).map(\.step), [.inspect])
        XCTAssertTrue(store.garden.records.allSatisfy { $0.kind == .change })
        XCTAssertEqual(PestAssessment(extent: .widespread).recommendation, .expert)
        XCTAssertEqual(PestAssessment(signs: .cotton).recommendation, .inspection)
    }

}
