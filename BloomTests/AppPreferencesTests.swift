import XCTest
import UserNotifications
@testable import Bloom

@MainActor private final class TestNotifications: BloomNotificationClient {
    var permission = BloomNotificationAccess.allowed
    var requests: [String: UNNotificationRequest] = [:]
    var authorizationRequests = 0
    var failScheduling = false
    func access() async -> BloomNotificationAccess { permission }
    func requestAccess() async throws -> Bool { authorizationRequests += 1; return permission == .allowed }
    func pending() async -> [UNNotificationRequest] { Array(requests.values) }
    func add(_ request: UNNotificationRequest) async throws {
        if failScheduling { throw CocoaError(.fileWriteUnknown) }
        requests[request.identifier] = request
    }
    func remove(_ identifiers: [String]) { for id in identifiers { requests[id] = nil } }
}

@MainActor final class AppPreferencesTests: XCTestCase {
    private var folder: URL!
    override func setUp() { folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString) }
    override func tearDown() { try? FileManager.default.removeItem(at: folder) }
    private var url: URL { folder.appending(path: "garden.json") }
    private func store(_ notifications: TestNotifications? = nil) -> BloomStore {
        BloomStore(fileURL: url, notificationClient: notifications ?? TestNotifications())
    }
    func testUnitTestStoresNeverTouchSystemNotificationScheduler() {
        XCTAssertFalse(BloomStore(fileURL: url).allowsPlanNotifications)
    }
    func testDiscoveryOffRetainsChoicesAndReusesSavedCityAfterRelaunch() {
        let s = store(); XCTAssertTrue(s.start(sample: false))
        let profile = PlantSearchPreferences(area: "Berlin", light: .lower, location: .berlin, plantTypes: [.bushy, .trailing])
        XCTAssertTrue(s.savePlantSearchPreferences(profile))
        XCTAssertTrue(s.setPersonalizedPicks(false)); XCTAssertNil(s.discoveryPreferences)
        let loaded = store()
        XCTAssertEqual(loaded.plantSearchPreferences, profile); XCTAssertNil(loaded.discoveryPreferences)
        XCTAssertTrue(loaded.setPersonalizedPicks(true)); XCTAssertEqual(loaded.discoveryPreferences, profile)
    }
    func testDefaultTimePersistsWithoutChangingExistingReminderOrPlan() async {
        let s = store(); XCTAssertTrue(s.start(sample: true))
        let observation = CareRecord(plantID: s.garden.plants[0].id, kind: .change, area: .pests, observation: "Visible insects")
        XCTAssertTrue(s.saveRecord(observation))
        XCTAssertNotNil(s.startCarePlan(observationID: observation.id, answers: PestAssessment(signs: .cotton, location: .joints, extent: .few, placement: .indoor), reviewDays: 7))
        let plants = s.garden.plants, records = s.garden.records, tasks = s.careTasks, plans = s.carePlans
        XCTAssertTrue(s.setDefaultReminderTime(hour: 16, minute: 25))
        XCTAssertEqual(s.garden.plants, plants); XCTAssertEqual(s.garden.records, records)
        XCTAssertEqual(s.careTasks, tasks); XCTAssertEqual(s.carePlans, plans)
        XCTAssertEqual(store().appPreferences.reminderHour, 16); XCTAssertEqual(store().appPreferences.reminderMinute, 25)
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 24, hour: 23))!
        let due = s.newReminderDate(days: 1, now: now, calendar: calendar)
        XCTAssertEqual(calendar.component(.day, from: due), 25)
        XCTAssertEqual(calendar.component(.hour, from: due), 16); XCTAssertEqual(calendar.component(.minute, from: due), 25)
        XCTAssertFalse(s.setDefaultReminderTime(hour: 24, minute: 0)); XCTAssertFalse(s.setDefaultReminderTime(hour: 9, minute: -1))
    }
    func testDeniedPermissionStillSavesTaskAndDoesNotRepeatedlyAsk() async {
        let n = TestNotifications(); n.permission = .denied
        let s = store(n); XCTAssertTrue(s.start(sample: true))
        let plant = s.garden.plants[0], due = Date().addingTimeInterval(86400)
        let result = await s.setReminder(for: plant.id, date: due)
        XCTAssertNil(result); XCTAssertEqual(s.plant(plant.id)?.reminder, due)
        XCTAssertEqual(n.authorizationRequests, 0); XCTAssertTrue(n.requests.isEmpty)
        let enabling = await s.setTaskNotifications(true)
        XCTAssertNotNil(enabling); XCTAssertFalse(s.appPreferences.taskNotifications)
        XCTAssertEqual(n.authorizationRequests, 1)
        _ = await s.setReminder(for: plant.id, days: 3)
        XCTAssertEqual(n.authorizationRequests, 1)
    }
    func testMuteAndReenablePreserveTasksAndOnlyRestoreFutureAlerts() async {
        let n = TestNotifications()
        let saved = BloomStore(fileURL: url, notificationClient: n)
        XCTAssertTrue(saved.start(sample: true))
        let plant = saved.garden.plants[0]
        _ = await saved.setReminder(for: plant.id, date: Date().addingTimeInterval(3600))
        let baseline = saved.garden.plants
        let enabled = await saved.setTaskNotifications(true); XCTAssertNil(enabled)
        XCTAssertNotNil(n.requests[plant.id.uuidString])
        let muted = await saved.setTaskNotifications(false); XCTAssertNil(muted)
        XCTAssertTrue(n.requests.isEmpty); XCTAssertEqual(saved.garden.plants, baseline)
        _ = saved.commit { $0.plants[0].reminder = Date().addingTimeInterval(-60) }
        let again = await saved.setTaskNotifications(true); XCTAssertNil(again)
        XCTAssertNil(n.requests[plant.id.uuidString]); XCTAssertLessThan(saved.plant(plant.id)!.reminder!, Date())
        XCTAssertFalse(n.requests.isEmpty) // Other, future sample tasks still receive alerts.
    }
    func testPlanNotificationOptInSurvivesGlobalMute() async {
        let n = TestNotifications(), s = store(n); XCTAssertTrue(s.start(sample: true))
        let plant = s.garden.plants[0]
        let record = CareRecord(plantID: plant.id, kind: .change, area: .pests, observation: "Visible insects")
        XCTAssertTrue(s.saveRecord(record))
        let answers = PestAssessment(signs: .cotton, location: .joints, extent: .few, placement: .indoor)
        let id = s.startCarePlan(observationID: record.id, answers: answers, reviewDays: 7)!
        let task = s.tasks(for: id).first!
        let off = await s.enablePlanNotification(task.id); XCTAssertNotNil(off)
        _ = await s.setTaskNotifications(true)
        let on = await s.enablePlanNotification(task.id); XCTAssertNil(on)
        XCTAssertNotNil(n.requests["bloom-plan-\(task.id.uuidString)"])
        _ = await s.setTaskNotifications(false)
        XCTAssertTrue(s.careTask(task.id)!.notifications); XCTAssertEqual(s.careTask(task.id)?.status, .pending)
        XCTAssertTrue(n.requests.isEmpty)
        _ = await s.setTaskNotifications(true)
        XCTAssertNotNil(n.requests["bloom-plan-\(task.id.uuidString)"])
        XCTAssertTrue(s.disablePlanNotification(task.id)); await s.waitForNotificationSync()
        XCTAssertNil(n.requests["bloom-plan-\(task.id.uuidString)"])
    }
    func testLegacyGardenKeepsExistingAlertIntentAndDoesNotRewriteOnRead() throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let bytes = Data("{\"plants\":[],\"records\":[],\"hasStarted\":true,\"isSample\":false}".utf8)
        try bytes.write(to: url)
        let s = store(); XCTAssertTrue(s.appPreferences.taskNotifications); XCTAssertTrue(s.appPreferences.personalizedPicks)
        XCTAssertEqual(try Data(contentsOf: url), bytes)
        XCTAssertTrue(s.setDefaultReminderTime(hour: 10, minute: 30))
        XCTAssertTrue(store().appPreferences.taskNotifications)
    }
    func testFailedPreferenceWritePreservesGardenAndSearchChoices() throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let blocker = folder.appending(path: "blocker"); try Data([0]).write(to: blocker)
        let s = BloomStore(fileURL: blocker.appending(path: "garden.json"), managesNotifications: false)
        XCTAssertFalse(s.setPersonalizedPicks(false)); XCTAssertTrue(s.appPreferences.personalizedPicks)
        XCTAssertFalse(s.setDefaultReminderTime(hour: 15, minute: 0)); XCTAssertEqual(s.appPreferences.reminderHour, 9)
    }
    func testSchedulingFailureDoesNotLoseTaskOrMisreportStorageFailure() async {
        let n = TestNotifications(), s = store(n); XCTAssertTrue(s.start(sample: true))
        n.failScheduling = true
        let message = await s.setTaskNotifications(true); XCTAssertNotNil(message)
        let p = s.garden.plants[0], due = Date().addingTimeInterval(3600)
        let saved = await s.setReminder(for: p.id, date: due)
        XCTAssertNil(saved); XCTAssertEqual(s.plant(p.id)?.reminder, due)
        XCTAssertNil(s.errorMessage); XCTAssertNotNil(s.notificationMessage)
    }
    func testMutingOneReminderKeepsItsTaskAndOtherAlertsThroughGlobalMuteAndRelaunch() async throws {
        let notifications = TestNotifications(), s = store(notifications)
        XCTAssertTrue(s.start(sample: true))
        let first = s.garden.plants[0], second = s.garden.plants[1]
        let due = Date().addingTimeInterval(86400)
        let result = await s.setReminder(for: first.id, date: due, notify: false)
        XCTAssertNil(result)
        let enabled = await s.setTaskNotifications(true); XCTAssertNil(enabled)
        XCTAssertEqual(s.plant(first.id)?.reminder, due)
        XCTAssertNil(notifications.requests[first.id.uuidString])
        XCTAssertNotNil(notifications.requests[second.id.uuidString])
        let loaded = store(notifications)
        XCTAssertEqual(loaded.plant(first.id)?.reminderNotifications, false)
        _ = await loaded.setTaskNotifications(false)
        _ = await loaded.setTaskNotifications(true)
        XCTAssertNil(notifications.requests[first.id.uuidString])
        XCTAssertNotNil(notifications.requests[second.id.uuidString])
        let updated = await loaded.setReminder(for: first.id, date: due, notify: true)
        XCTAssertNil(updated)
        XCTAssertNotNil(notifications.requests[first.id.uuidString])
    }

}
