import Foundation
import UserNotifications

extension BloomStore {
    var wateringSchedules: [WateringSchedule] { garden.wateringSchedules }

    func wateringSchedule(for plantID: UUID) -> WateringSchedule? {
        wateringSchedules.first { $0.plantID == plantID }
    }

    func wateringProfile(for plantID: UUID) -> WateringProfile? {
        plant(plantID).flatMap(WateringProfile.forPlant)
    }

    func wateringProfile(for plant: Plant) -> WateringProfile? {
        WateringProfile.forPlant(plant)
    }

    func wateringTiming(for plantID: UUID, now: Date = .now, calendar: Calendar = .current) -> CareTaskTiming? {
        wateringSchedule(for: plantID).map { CareTaskTiming.classify($0.nextCheckAt, now: now, calendar: calendar) }
    }

    @discardableResult
    func editNextCheck(for plantID: UUID, date: Date, now: Date = .now) -> Bool {
        guard date >= now, let current = wateringSchedule(for: plantID) else { return false }
        return commit { garden in
            guard let index = garden.wateringSchedules.firstIndex(where: { $0.id == current.id }) else { return }
            garden.wateringSchedules[index].nextCheckAt = date
            garden.wateringSchedules[index].updatedAt = now
        }
    }

    func setTaskNotifications(_ enabled: Bool) async -> String? {
        if enabled {
            do {
                guard try await notificationClient.requestAccess() else { return "Notifications are off in iOS Settings. Your tasks stay in Bloom." }
            } catch {
                return "Notification access couldn't be enabled. Your tasks stay in Bloom."
            }
        }
        guard commit({ $0.appPreferences.taskNotifications = enabled }) else {
            return "Your notification preference couldn't be saved."
        }
        syncWateringNotifications()
        await waitForNotificationSync()
        return notificationMessage
    }

    func syncWateringNotifications() {
        let previous = notificationSyncTask
        notificationSyncTask = Task { [weak self] in
            await previous?.value
            await self?.performWateringNotificationSync()
        }
    }

    func waitForNotificationSync() async { await notificationSyncTask?.value }

    private func performWateringNotificationSync() async {
        let pending = await notificationClient.pending()
        let managed = pending.map(\.identifier).filter { $0.hasPrefix("bloom-watering-") }
        let future = garden.appPreferences.taskNotifications
            ? wateringSchedules.filter { $0.nextCheckAt > Date() }
            : []
        let desiredIDs = Set(future.map { wateringNotificationID(for: $0.plantID) })
        notificationClient.remove(managed.filter { !desiredIDs.contains($0) })
        guard garden.appPreferences.taskNotifications, await notificationClient.access() == .allowed else { return }
        for schedule in future {
            guard let plant = plant(schedule.plantID), let trigger = calendarNotificationTrigger(for: schedule.nextCheckAt) else { continue }
            let content = UNMutableNotificationContent()
            content.title = "Check watering"
            content.body = "Check \(plant.displayName)'s soil before deciding whether to water."
            content.sound = .default
            content.userInfo = ["plantID": plant.id.uuidString]
            do {
                try await notificationClient.add(UNNotificationRequest(identifier: wateringNotificationID(for: plant.id), content: content, trigger: trigger))
            } catch {
                notificationMessage = "A watering notification couldn't be scheduled. Your task stays in Bloom."
            }
        }
    }

    private func calendarNotificationTrigger(for date: Date) -> UNCalendarNotificationTrigger? {
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    }

    func wateringNotificationID(for plantID: UUID) -> String { "bloom-watering-\(plantID.uuidString)" }

    @discardableResult
    func completeWateringCheck(
        for plantID: UUID,
        outcome: WateringOutcome,
        soil: Soil,
        note: String = "",
        now: Date = .now,
        calendar: Calendar = .current,
        followUpDays: Int? = nil
    ) -> WateringRecord? {
        guard let schedule = wateringSchedule(for: plantID), let profile = wateringProfile(for: plantID) else { return nil }
        guard soil != .unknown || followUpDays == nil else { return nil }
        if let followUpDays, !WateringFollowUp.allowedDays.contains(followUpDays) { return nil }
        let intervalDays: Int
        switch outcome {
        case .watered: intervalDays = profile.startingIntervalDays
        case .checkedNotWatered:
            intervalDays = followUpDays ?? profile.startingIntervalDays
        }
        let next = calendar.date(byAdding: .day, value: intervalDays, to: now) ?? now.addingTimeInterval(TimeInterval(intervalDays * 86_400))
        let record = WateringRecord(plantID: plantID, scheduledFor: schedule.nextCheckAt, recordedAt: now, outcome: outcome, soil: soil, note: note)
        guard commit({ garden in
            garden.wateringRecords.insert(record, at: 0)
            if let index = garden.wateringSchedules.firstIndex(where: { $0.id == schedule.id }) {
                garden.wateringSchedules[index].nextCheckAt = next
                garden.wateringSchedules[index].updatedAt = now
            }
        }) else { return nil }
        return record
    }

    @discardableResult
    func deleteLatestWateringRecord(for plantID: UUID) -> Bool {
        guard let latest = records(for: plantID).first else { return false }
        return commit { garden in
            garden.wateringRecords.removeAll { $0.id == latest.id }
            guard let scheduleIndex = garden.wateringSchedules.firstIndex(where: { $0.plantID == plantID }) else { return }
            if let previous = garden.wateringRecords.filter({ $0.plantID == plantID }).max(by: { $0.recordedAt < $1.recordedAt }) {
                garden.wateringSchedules[scheduleIndex].nextCheckAt = previous.recordedAt
            }
        }
    }
}
