import SwiftUI
import UIKit
import UserNotifications
import Observation

@main
struct BloomApp: App {
    @UIApplicationDelegateAdaptor(BloomNotificationDelegate.self) private var notificationDelegate
    @State private var store = BloomStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .background(BloomTheme.canvas.ignoresSafeArea())
                .environment(store)
                .tint(BloomTheme.teal)
                .preferredColorScheme(.light)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { store.refreshPlanTaskNotifications() }
                }
                .alert("Your changes couldn't be saved", isPresented: Binding(
                    get: { store.errorMessage != nil },
                    set: { if !$0 { store.errorMessage = nil } }
                )) {
                    Button("OK", role: .cancel) { store.errorMessage = nil }
                } message: {
                    Text(store.errorMessage ?? "Please try again. Your previous records are safe.")
                }
        }
    }
}

@MainActor @Observable final class BloomNotificationRouter {
    static let shared = BloomNotificationRouter()
    var plantID: UUID?
    var planTaskID: UUID?
}

@MainActor final class BloomNotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let raw = response.notification.request.content.userInfo["plantID"] as? String ?? response.notification.request.identifier
        let taskID = response.notification.request.content.userInfo["taskID"] as? String
        Task { @MainActor in
            if let taskID { BloomNotificationRouter.shared.planTaskID = UUID(uuidString: taskID) }
            else { BloomNotificationRouter.shared.plantID = UUID(uuidString: raw) }
            completionHandler()
        }
    }
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
