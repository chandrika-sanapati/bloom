import Foundation
import UserNotifications

struct AppPreferences: Codable, Equatable {
    var personalizedPicks = true
    var taskNotifications = false
    var reminderHour = 9
    var reminderMinute = 0
}

enum BloomNotificationAccess: String {
    case notRequested = "Not enabled", allowed = "Allowed", denied = "Off in iOS Settings"
}

@MainActor protocol BloomNotificationClient {
    func access() async -> BloomNotificationAccess
    func requestAccess() async throws -> Bool
    func pending() async -> [UNNotificationRequest]
    func add(_ request: UNNotificationRequest) async throws
    func remove(_ identifiers: [String])
}

@MainActor final class SystemBloomNotifications: BloomNotificationClient {
    private var center: UNUserNotificationCenter { .current() }
    func access() async -> BloomNotificationAccess {
        switch await center.notificationSettings().authorizationStatus {
        case .authorized, .provisional, .ephemeral: .allowed
        case .denied: .denied
        default: .notRequested
        }
    }
    func requestAccess() async throws -> Bool { try await center.requestAuthorization(options: [.alert, .sound]) }
    func pending() async -> [UNNotificationRequest] { await center.pendingNotificationRequests() }
    func add(_ request: UNNotificationRequest) async throws { try await center.add(request) }
    func remove(_ identifiers: [String]) { center.removePendingNotificationRequests(withIdentifiers: identifiers) }
}

/// Used only by isolated UI tests; it never changes device permissions or schedules system alerts.
@MainActor final class PreviewBloomNotifications: BloomNotificationClient {
    var permission: BloomNotificationAccess
    init() { permission = ProcessInfo.processInfo.arguments.contains("--uitesting-notifications-denied") ? .denied : .allowed }
    func access() async -> BloomNotificationAccess { permission }
    func requestAccess() async throws -> Bool { permission == .allowed }
    func pending() async -> [UNNotificationRequest] { [] }
    func add(_ request: UNNotificationRequest) async throws {}
    func remove(_ identifiers: [String]) {}
}

extension BloomStore {
    var appPreferences: AppPreferences {
        // Older gardens retain existing opted-in alerts. New gardens begin quietly.
        garden.appPreferences ?? AppPreferences(taskNotifications: garden.hasStarted)
    }
    var discoveryPreferences: PlantSearchPreferences? { appPreferences.personalizedPicks ? plantSearchPreferences : nil }

    @discardableResult func setPersonalizedPicks(_ enabled: Bool) -> Bool {
        var next = appPreferences; next.personalizedPicks = enabled
        return commit { $0.appPreferences = next }
    }
    @discardableResult func setDefaultReminderTime(hour: Int, minute: Int) -> Bool {
        guard (0...23).contains(hour), (0...59).contains(minute) else { return false }
        var next = appPreferences; next.reminderHour = hour; next.reminderMinute = minute
        return commit { $0.appPreferences = next }
    }
    func newReminderDate(days: Int = 3, now: Date = .now, calendar: Calendar = .current) -> Date {
        let day = calendar.date(byAdding: .day, value: max(1, days), to: now) ?? now.addingTimeInterval(86400)
        return calendar.date(bySettingHour: appPreferences.reminderHour, minute: appPreferences.reminderMinute, second: 0, of: day) ?? day
    }
    func setTaskNotifications(_ enabled: Bool) async -> String? {
        if enabled {
            do {
                guard try await notificationClient.requestAccess() else { return "Notifications are off in iOS Settings. Your tasks stay in Bloom." }
            } catch { return "Notification access couldn't be enabled. Your tasks stay in Bloom." }
        }
        var next = appPreferences; next.taskNotifications = enabled
        guard commit({ $0.appPreferences = next }) else { return "Your notification preference couldn't be saved." }
        await waitForNotificationSync()
        return notificationMessage
    }
    var growingSpaceSummary: String {
        guard let profile = plantSearchPreferences else { return "Choose your area, light & plants" }
        var parts: [String] = []
        if !profile.area.isEmpty { parts.append(profile.displayArea) }
        if profile.light != .unsure { parts.append(profile.light.rawValue) }
        if !profile.selectedTypes.isEmpty { parts.append("\(profile.selectedTypes.count) plant types") }
        return parts.isEmpty ? "All plant shapes · Light not set" : parts.joined(separator: " · ")
    }
}
