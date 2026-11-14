import XCTest
import UserNotifications
@testable import Bloom

@MainActor
final class Phase5NotificationTests: XCTestCase {
    private func temporaryURL() -> URL {
        FileManager.default.temporaryDirectory.appending(path: UUID().uuidString).appending(path: "garden.json")
    }

    func testNotificationPermissionDeniedKeepsTasksInBloom() async {
        let notifications = PreviewBloomNotifications()
        notifications.permission = .denied
        let store = BloomStore(fileURL: temporaryURL(), notificationClient: notifications)
        let plant = Plant(name: "Pothos", species: "Epipremnum aureum", asset: "pothos")
        XCTAssertTrue(store.addPlant(plant))

        let message = await store.setTaskNotifications(true)
        XCTAssertNotNil(message)
        XCTAssertFalse(store.garden.appPreferences.taskNotifications)
        XCTAssertNotNil(store.schedule(plant.id))
    }

    func testOnlyFutureSchedulesAreNotifiedAndOverdueDoesNotCreateAlerts() async throws {
        let notifications = PreviewBloomNotifications()
        let store = BloomStore(fileURL: temporaryURL(), notificationClient: notifications)
        let plant = Plant(name: "Monstera", species: "Monstera deliciosa", asset: "monstera")
        XCTAssertTrue(store.addPlant(plant))
        let future = Date().addingTimeInterval(86_400)
        XCTAssertTrue(store.editNextCheck(for: plant.id, date: future))
        let enableMessage = await store.setTaskNotifications(true)
        XCTAssertNil(enableMessage)
        XCTAssertNotNil(notifications.requests[store.wateringNotificationID(for: plant.id)])

        XCTAssertTrue(store.commit { garden in
            if let index = garden.wateringSchedules.firstIndex(where: { $0.plantID == plant.id }) {
                garden.wateringSchedules[index].nextCheckAt = Date().addingTimeInterval(-60)
            }
        })
        await store.waitForNotificationSync()
        XCTAssertNil(notifications.requests[store.wateringNotificationID(for: plant.id)])
    }

    func testDisablingNotificationsRemovesWateringAlertsButKeepsSchedule() async throws {
        let notifications = PreviewBloomNotifications()
        let store = BloomStore(fileURL: temporaryURL(), notificationClient: notifications)
        let plant = Plant(name: "Snake Plant", species: "Dracaena trifasciata", asset: "snake")
        XCTAssertTrue(store.addPlant(plant))
        let enableMessage = await store.setTaskNotifications(true)
        XCTAssertNil(enableMessage)
        XCTAssertNotNil(notifications.requests[store.wateringNotificationID(for: plant.id)])

        let disableMessage = await store.setTaskNotifications(false)
        XCTAssertNil(disableMessage)
        XCTAssertTrue(notifications.requests.isEmpty)
        XCTAssertNotNil(store.schedule(plant.id))
    }
}
