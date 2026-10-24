import XCTest
@testable import Bloom

@MainActor final class AuditTests: XCTestCase {
    func testInspectionTasksAreIndependentAndFollowUpIsExplicit() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appending(path: "garden.json")
        let store = BloomStore(fileURL: url, managesNotifications: false)
        let plant = Plant(name: "Desk plant", species: "Monstera deliciosa", asset: "monstera")
        XCTAssertTrue(store.savePlant(plant))
        let observation = CareRecord(plantID: plant.id, kind: .change, area: .leaves, observation: "Dropping leaves")
        XCTAssertTrue(store.saveRecord(observation))
        let id = try XCTUnwrap(store.startLeafCarePlan(observationID: observation.id, answers: LeafAssessment(), reviewDays: nil))
        let tasks = store.tasks(for: id)
        XCTAssertEqual(tasks.map(\.step), [.checkSoilMoisture, .checkGrowingConditions, .checkLeafChanges])
        XCTAssertNotNil(store.finishPlanAction(taskID: tasks[0].id))
        XCTAssertEqual(store.careTask(tasks[1].id)?.status, .pending)
        XCTAssertNil(store.wateredDate(for: plant))
        XCTAssertNotNil(store.finishPlanAction(taskID: tasks[1].id))
        let receipt = try XCTUnwrap(store.finishPlanAction(taskID: tasks[2].id))
        XCTAssertFalse(store.tasks(for: id).contains { $0.step == .review })
        let date = Date().addingTimeInterval(259200)
        XCTAssertTrue(store.schedulePlanReview(id, date: date))
        XCTAssertEqual(store.tasks(for: id).last?.due, date)
        XCTAssertTrue(store.undoPlanTask(receipt))
        XCTAssertEqual(store.careTask(tasks[2].id)?.status, .pending)
        let loaded = BloomStore(fileURL: url, managesNotifications: false)
        XCTAssertEqual(loaded.tasks(for: id).map(\.step), [.checkSoilMoisture, .checkGrowingConditions, .checkLeafChanges, .review])
        XCTAssertEqual(loaded.carePlan(id)?.baseline, observation)
        XCTAssertEqual(loaded.record(observation.id)?.observation, observation.observation)
        XCTAssertEqual(loaded.record(observation.id)?.leafAssessment, LeafAssessment())
    }
    func testLegacyCombinedStepStillDecodesAndKnownReferencesResolve() throws {
        let data = Data("\"inspectGrowingConditions\"".utf8)
        XCTAssertEqual(try JSONDecoder().decode(CarePlanStep.self, from: data), .inspectGrowingConditions)
        for species in PlantSpecies.catalog {
            XCTAssertNotNil(Plant(name: species.name, species: species.scientific, asset: species.asset).referenceURL)
        }
        XCTAssertNil(Plant(name: "Unknown", species: "Unknown", asset: "").referenceURL)
    }

    func testSkippingEveryActionWithoutFollowUpRequiresReview() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = BloomStore(fileURL: folder.appending(path: "garden.json"), managesNotifications: false)
        let plant = Plant(name: "Milo", species: "Monstera deliciosa", asset: "monstera")
        XCTAssertTrue(store.savePlant(plant))
        let observation = CareRecord(plantID: plant.id, kind: .change, area: .leaves, observation: "Dropping leaves")
        XCTAssertTrue(store.saveRecord(observation))
        let id = try XCTUnwrap(store.startLeafCarePlan(observationID: observation.id, answers: LeafAssessment(), reviewDays: nil))
        for task in store.tasks(for: id) { XCTAssertNotNil(store.finishPlanAction(taskID: task.id, skipped: true)) }
        XCTAssertEqual(store.carePlan(id)?.status, .needsReview)
        XCTAssertFalse(store.tasks(for: id).contains { $0.step == .review })
        XCTAssertNil(store.wateredDate(for: plant))
    }
}
