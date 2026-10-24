import XCTest
@testable import Bloom

@MainActor final class LeafCareTests: XCTestCase {
    private var folder: URL!
    private var url: URL { folder.appending(path: "garden.json") }
    override func setUp() { folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString) }
    override func tearDown() { try? FileManager.default.removeItem(at: folder) }
    private var answers: LeafAssessment {
        LeafAssessment(soil: .dry, drainage: .yes, environment: .no, warning: LeafWarning.none, placement: .indoor)
    }
    private func fixture() -> (BloomStore, Plant, CareRecord) {
        let s = BloomStore(fileURL: url, managesNotifications: false)
        let plant = Plant(name: "Milo", species: "Monstera deliciosa", asset: "monstera", placement: .indoor)
        XCTAssertTrue(s.savePlant(plant))
        let record = CareRecord(plantID: plant.id, kind: .change, area: .leaves, observation: "Dropping leaves", note: "Two leaves since yesterday", photo: Data([1, 2, 3]))
        XCTAssertTrue(s.saveRecord(record)); return (s, plant, record)
    }
    func testLeafAndPestObservationsUseAppropriateChecksAndLegacyResume() {
        let (_, _, record) = fixture()
        XCTAssertTrue(ObservationGuidanceRoute.isLeaf(record))
        var old = record; old.area = .pests
        XCTAssertFalse(ObservationGuidanceRoute.isLeaf(old))
        old.area = .leaves; old.assessment = PestAssessment()
        XCTAssertFalse(ObservationGuidanceRoute.isLeaf(old))
        old.leafAssessment = answers
        XCTAssertTrue(ObservationGuidanceRoute.isLeaf(old))
    }
    func testNewPestObservationsOfferVisualInspectionWithoutInventedChecks() throws {
        let (s, _, original) = fixture()
        var record = original; record.area = .pests; record.observation = "Visible insects"
        XCTAssertTrue(s.saveRecord(record))
        XCTAssertTrue(ObservationGuidanceRoute.usesVisualEntry(record))
        let id = try XCTUnwrap(s.startPestInspectionPlan(observationID: record.id, reviewDays: 3))
        XCTAssertEqual(s.carePlan(id)?.kind, .inspection)
        XCTAssertNil(s.carePlan(id)?.assessment); XCTAssertNil(s.carePlan(id)?.leafAssessment)
        XCTAssertEqual(s.carePlan(id)?.baseline, record)
        XCTAssertEqual(s.tasks(for: id).map(\.step), [.inspect, .review])
        XCTAssertNil(s.tasks(for: id).last?.due)
        XCTAssertEqual(s.garden.records.count, 1)
        XCTAssertNil(s.startPestInspectionPlan(observationID: original.id, reviewDays: 0))
        record.assessment = PestAssessment(signs: .webbing)
        XCTAssertFalse(ObservationGuidanceRoute.usesVisualEntry(record))
    }
    func testDryWetAndEnvironmentEvidenceProduceDifferentStartingActions() {
        let (_, plant, record) = fixture()
        XCTAssertEqual(answers.recommendation(for: record, plant: plant), .leafDry)
        var wet = answers; wet.soil = .soggy
        XCTAssertEqual(wet.recommendation(for: record, plant: plant), .leafWet)
        XCTAssertFalse(CarePlanKind.leafWet.actionSteps.contains(.waterDryRoots))
        var moved = answers; moved.soil = .moist; moved.environment = .yes
        XCTAssertEqual(moved.recommendation(for: record, plant: plant), .leafEnvironment)
    }
    func testUnknownSpeciesSpotsOutdoorsNoDrainageAndUncertaintyNeverAssumeWatering() {
        let (_, plant, record) = fixture()
        var unknown = plant; unknown.species = ""
        XCTAssertEqual(answers.recommendation(for: record, plant: unknown), .leafInspection)
        var spots = record; spots.observation = "Spots or patches"
        XCTAssertEqual(answers.recommendation(for: spots, plant: plant), .leafInspection)
        for soil in [LeafSoil.moist, .unsure] {
            var a = answers; a.soil = soil
            XCTAssertEqual(a.recommendation(for: record, plant: plant), .leafInspection)
        }
        var a = answers; a.placement = .outdoor
        XCTAssertEqual(a.recommendation(for: record, plant: plant), .leafInspection)
        a = answers; a.drainage = .no
        XCTAssertEqual(a.recommendation(for: record, plant: plant), .leafInspection)
        a = answers; a.warning = .unsure
        XCTAssertEqual(a.recommendation(for: record, plant: plant), .leafInspection)
        a.warning = .pests
        XCTAssertEqual(a.recommendation(for: record, plant: plant), .leafInspection)
    }
    func testSevereSignsTakePriorityOverWaterAndRecentMoves() {
        let (_, plant, record) = fixture()
        for sign in [LeafWarning.soft, .rapid] {
            var a = answers; a.warning = sign; a.soil = .soggy; a.environment = .yes
            XCTAssertEqual(a.recommendation(for: record, plant: plant), .leafExpert)
        }
        var stem = record; stem.area = .stems; stem.observation = "Soft or mushy"
        XCTAssertEqual(LeafAssessment().recommendation(for: stem, plant: plant), .leafExpert)
        XCTAssertTrue(CarePlanKind.leafExpert.needsSpecialist)
    }
    func testSavingChecksDoesNotStartAPlanOrRecordAnAction() throws {
        let (s, _, record) = fixture()
        XCTAssertTrue(s.saveLeafAssessment(answers, observationID: record.id))
        XCTAssertTrue(s.carePlans.isEmpty); XCTAssertTrue(s.careTasks.isEmpty)
        XCTAssertEqual(s.garden.records.count, 1)
        let loaded = BloomStore(fileURL: url, managesNotifications: false)
        XCTAssertEqual(loaded.record(record.id)?.leafAssessment, answers)
        XCTAssertNil(s.startLeafCarePlan(observationID: record.id, answers: answers, reviewDays: 0))
    }
    func testNoChecksCanStartAnInspectionTaskWithoutInventedAnswers() throws {
        let (s, _, record) = fixture()
        let id = try XCTUnwrap(s.startLeafCarePlan(observationID: record.id, answers: LeafAssessment(), reviewDays: 3))
        XCTAssertEqual(s.carePlan(id)?.kind, .leafInspection)
        XCTAssertEqual(s.carePlan(id)?.leafAssessment, LeafAssessment())
        XCTAssertEqual(s.carePlan(id)?.baseline, record)
        XCTAssertEqual(s.tasks(for: id).map(\.step), [.checkSoilMoisture, .checkGrowingConditions, .checkLeafChanges, .review])
        XCTAssertNil(s.tasks(for: id).last?.due)
        XCTAssertEqual(s.garden.records.count, 1)
        let loaded = BloomStore(fileURL: url, managesNotifications: false)
        XCTAssertEqual(loaded.carePlan(id), s.carePlan(id))
    }
    func testOnlyRelevantEvidenceIsRequiredAndKnownPlacementIsReused() {
        let (_, plant, record) = fixture()
        var a = LeafAssessment(soil: .soggy, warning: LeafWarning.none)
        XCTAssertFalse(a.complete)
        XCTAssertEqual(a.recommendation(for: record, plant: plant), .leafWet)
        a.soil = .dry
        XCTAssertEqual(a.recommendation(for: record, plant: plant), .leafInspection)
        a.drainage = .yes
        XCTAssertEqual(a.recommendation(for: record, plant: plant), .leafDry)
        a.placement = .unsure
        XCTAssertEqual(a.recommendation(for: record, plant: plant), .leafInspection)
        a.placement = nil; a.warning = nil
        XCTAssertEqual(a.recommendation(for: record, plant: plant), .leafInspection)
        a.warning = .pests
        XCTAssertEqual(a.recommendation(for: record, plant: plant), .leafInspection)
        a.warning = .soft
        XCTAssertEqual(a.recommendation(for: record, plant: plant), .leafExpert)
    }
    func testPartialPlanFailureDoesNotLoseTheSavedObservation() throws {
        let (s, _, record) = fixture()
        try FileManager.default.removeItem(at: folder)
        try Data([0]).write(to: folder)
        XCTAssertNil(s.startLeafCarePlan(observationID: record.id, answers: LeafAssessment(), reviewDays: nil))
        XCTAssertEqual(s.record(record.id), record)
        XCTAssertTrue(s.careTasks.isEmpty); XCTAssertTrue(s.carePlans.isEmpty)
    }
    func testAcceptedPlanPreservesBaselineAndStartsThreeDaysAfterActualAction() throws {
        let (s, plant, record) = fixture()
        let id = try XCTUnwrap(s.startLeafCarePlan(observationID: record.id, answers: answers, reviewDays: 3))
        let action = s.tasks(for: id)[0], review = s.tasks(for: id)[1]
        XCTAssertEqual(s.carePlan(id)?.baseline, record); XCTAssertEqual(s.carePlan(id)?.leafAssessment, answers)
        XCTAssertNil(s.carePlan(id)?.assessment); XCTAssertEqual(s.carePlan(id)?.guidanceVersion, "2026-10-24.1")
        XCTAssertEqual(review.status, .waiting); XCTAssertNil(review.due)
        XCTAssertEqual(s.garden.records.count, 1); XCTAssertNil(s.wateredDate(for: plant))
        XCTAssertEqual(s.startLeafCarePlan(observationID: record.id, answers: answers, reviewDays: 3), id)
        let performed = Date().addingTimeInterval(-3600)
        XCTAssertNotNil(s.finishPlanAction(taskID: action.id, now: performed, wateringAction: .watered))
        XCTAssertEqual(s.careTask(review.id)?.due, Calendar.current.date(byAdding: .day, value: 3, to: performed))
        XCTAssertEqual(s.wateredDate(for: plant), performed)
        XCTAssertFalse(s.careTask(review.id)!.notifications)
    }
    func testWateringNeedsAnExplicitDecisionAndUndoRestoresHistoryAndTimer() throws {
        let (s, plant, record) = fixture()
        let id = try XCTUnwrap(s.startLeafCarePlan(observationID: record.id, answers: answers, reviewDays: 3))
        let action = s.tasks(for: id)[0], review = s.tasks(for: id)[1]
        XCTAssertNil(s.finishPlanAction(taskID: action.id))
        let done = try XCTUnwrap(s.finishPlanAction(taskID: action.id, wateringAction: .watered))
        XCTAssertNotNil(s.wateredDate(for: plant)); XCTAssertTrue(s.undoPlanTask(done))
        XCTAssertNil(s.wateredDate(for: plant)); XCTAssertEqual(s.careTask(review.id)?.status, .waiting)
        XCTAssertNil(s.careTask(review.id)?.due)
        XCTAssertNotNil(s.finishPlanAction(taskID: action.id, wateringAction: .waited))
        XCTAssertNil(s.wateredDate(for: plant)); XCTAssertEqual(s.careTask(review.id)?.status, .pending)
        XCTAssertEqual(s.garden.records.first?.action, .waited)
    }
    func testSkippingAndDecliningFollowUpNeverStartAFalseRecoveryClock() throws {
        let (s, _, record) = fixture()
        let id = try XCTUnwrap(s.startLeafCarePlan(observationID: record.id, answers: answers, reviewDays: 3))
        XCTAssertNotNil(s.finishPlanAction(taskID: s.tasks(for: id)[0].id, skipped: true))
        XCTAssertEqual(s.tasks(for: id)[1].status, .waiting); XCTAssertNil(s.tasks(for: id)[1].due)
        XCTAssertEqual(s.carePlan(id)?.status, .needsReview)
        XCTAssertTrue(s.closePlan(id, resolved: false))
        let other = try XCTUnwrap(s.startLeafCarePlan(observationID: record.id, answers: answers, reviewDays: nil))
        XCTAssertEqual(s.tasks(for: other).count, 1)
    }
    func testExtraEarlyComparisonPreservesPlannedThreeDayCheckAndRequiresExplicitResolution() throws {
        let (s, _, record) = fixture()
        let id = try XCTUnwrap(s.startLeafCarePlan(observationID: record.id, answers: answers, reviewDays: 3))
        XCTAssertNotNil(s.finishPlanAction(taskID: s.tasks(for: id)[0].id, wateringAction: .waited))
        let automatic = s.tasks(for: id)[1], due = try XCTUnwrap(automatic.due)
        let early = try XCTUnwrap(s.reviewPlanNow(id))
        XCTAssertNotEqual(early, automatic.id)
        XCTAssertNotNil(s.finishPlanReview(taskID: early, outcome: .none, note: "No new drop"))
        XCTAssertEqual(s.careTask(automatic.id)?.status, .pending); XCTAssertEqual(s.careTask(automatic.id)?.due, due)
        XCTAssertEqual(s.carePlan(id)?.status, .active)
        XCTAssertEqual(s.garden.records.first?.outcome, "No new concerning changes")
        let chosenDate = due.addingTimeInterval(86400)
        XCTAssertTrue(s.reschedulePlanTask(automatic.id, date: chosenDate))
        let anotherEarly = try XCTUnwrap(s.reviewPlanNow(id))
        XCTAssertNotEqual(anotherEarly, automatic.id)
        XCTAssertEqual(s.careTask(automatic.id)?.due, chosenDate)
        XCTAssertTrue(s.closePlan(id, resolved: true)); XCTAssertEqual(s.careTask(automatic.id)?.status, .cancelled)
    }
    func testWorseLeafOutcomeCanBeReassessedWithoutChangingAnotherIssue() throws {
        let (s, plant, record) = fixture()
        let id = try XCTUnwrap(s.startLeafCarePlan(observationID: record.id, answers: answers, reviewDays: 3))
        var pest = record; pest.id = UUID(); pest.area = .pests; pest.observation = "Visible insects"
        XCTAssertTrue(s.saveRecord(pest))
        let pestID = try XCTUnwrap(s.startCarePlan(observationID: pest.id, answers: PestAssessment(signs: .cotton, location: .joints, extent: .few, placement: .indoor), reviewDays: 7))
        XCTAssertNotNil(s.finishPlanAction(taskID: s.tasks(for: id)[0].id, wateringAction: .waited))
        let early = try XCTUnwrap(s.reviewPlanNow(id))
        XCTAssertNotNil(s.finishPlanReview(taskID: early, outcome: .worse, note: "More leaf loss"))
        XCTAssertEqual(s.garden.records.first?.outcome, "More drooping or new damage")
        XCTAssertEqual(s.carePlan(id)?.status, .needsReview); XCTAssertFalse(s.closePlan(id, resolved: true))
        var changed = answers; changed.warning = .soft
        let revised = try XCTUnwrap(s.startLeafCarePlan(observationID: record.id, answers: changed, reviewDays: nil, replacing: id))
        XCTAssertEqual(s.carePlan(revised)?.kind, .leafExpert); XCTAssertEqual(s.carePlan(id)?.status, .stopped)
        XCTAssertEqual(s.carePlan(pestID)?.status, .active); XCTAssertNotNil(s.plant(plant.id))
    }
    func testLeafPlanPhotosTasksAndSettingsPersistAndOldPestPlansStillDecode() throws {
        let (s, _, record) = fixture()
        XCTAssertTrue(s.setDefaultReminderTime(hour: 16, minute: 20))
        let id = try XCTUnwrap(s.startLeafCarePlan(observationID: record.id, answers: answers, reviewDays: 3))
        XCTAssertNotNil(s.finishPlanAction(taskID: s.tasks(for: id)[0].id, wateringAction: .waited))
        let loaded = BloomStore(fileURL: url, managesNotifications: false)
        XCTAssertEqual(loaded.carePlan(id), s.carePlan(id)); XCTAssertEqual(loaded.careTasks, s.careTasks)
        XCTAssertEqual(loaded.carePlan(id)?.baseline.photo, record.photo); XCTAssertEqual(loaded.appPreferences.reminderHour, 16)
        let oldPlan = CarePlan(plantID: record.plantID, observationID: record.id, kind: .inspection, assessment: PestAssessment(signs: .unsure, location: .unsure, extent: .unsure, placement: .unsure), baseline: record)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(oldPlan)) as? [String: Any])
        json.removeValue(forKey: "leafAssessment")
        let bytes = try JSONSerialization.data(withJSONObject: json)
        let decoded = try JSONDecoder().decode(CarePlan.self, from: bytes)
        XCTAssertEqual(decoded.kind, .inspection); XCTAssertNotNil(decoded.assessment); XCTAssertNil(decoded.leafAssessment)
    }
    func testFailedLeafWritesDoNotCreatePartialPlansOrLoseObservation() throws {
        let (s, _, record) = fixture()
        try FileManager.default.removeItem(at: folder)
        try Data([0]).write(to: folder)
        XCTAssertFalse(s.saveLeafAssessment(answers, observationID: record.id))
        XCTAssertNil(s.startLeafCarePlan(observationID: record.id, answers: answers, reviewDays: 3))
        XCTAssertTrue(s.carePlans.isEmpty); XCTAssertTrue(s.careTasks.isEmpty)
        XCTAssertEqual(s.record(record.id), record)
    }
}
