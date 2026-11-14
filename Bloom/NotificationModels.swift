import Foundation
import UserNotifications

@MainActor
protocol BloomNotificationClient {
    func access() async -> BloomNotificationAccess
    func requestAccess() async throws -> Bool
    func pending() async -> [UNNotificationRequest]
    func add(_ request: UNNotificationRequest) async throws
    func remove(_ identifiers: [String])
}

enum BloomNotificationAccess {
    case notRequested
    case allowed
    case denied
}

@MainActor
final class SystemBloomNotifications: BloomNotificationClient {
    private let center = UNUserNotificationCenter.current()

    func access() async -> BloomNotificationAccess {
        switch await center.notificationSettings().authorizationStatus {
        case .authorized, .provisional, .ephemeral: .allowed
        case .denied: .denied
        default: .notRequested
        }
    }

    func requestAccess() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound])
    }

    func pending() async -> [UNNotificationRequest] {
        await center.pendingNotificationRequests()
    }

    func add(_ request: UNNotificationRequest) async throws {
        try await center.add(request)
    }

    func remove(_ identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}

@MainActor
final class PreviewBloomNotifications: BloomNotificationClient {
    var permission: BloomNotificationAccess = .allowed
    var requests: [String: UNNotificationRequest] = [:]
    var accessRequests = 0

    func access() async -> BloomNotificationAccess { permission }
    func requestAccess() async throws -> Bool { accessRequests += 1; return permission == .allowed }
    func pending() async -> [UNNotificationRequest] { Array(requests.values) }
    func add(_ request: UNNotificationRequest) async throws { requests[request.identifier] = request }
    func remove(_ identifiers: [String]) { identifiers.forEach { requests[$0] = nil } }
}
