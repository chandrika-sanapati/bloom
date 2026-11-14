import Foundation

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

    @discardableResult
    func ensureWateringSchedule(for plantID: UUID, now: Date = .now, calendar: Calendar = .current) -> Bool {
        guard let plant = plant(plantID), let profile = wateringProfile(for: plant), wateringSchedule(for: plantID) == nil else {
            return true
        }
        let schedule = WateringSchedule.initial(
            for: plant,
            profile: profile,
            lastWatered: lastWatered(for: plantID),
            now: now,
            reminderHour: garden.appPreferences.reminderHour,
            reminderMinute: garden.appPreferences.reminderMinute,
            calendar: calendar
        )
        return commit { garden in
            garden.wateringSchedules.append(schedule)
        }
    }

    @discardableResult
    func migrateWateringSchedules(now: Date = .now, calendar: Calendar = .current) -> Bool {
        let missing = garden.plants.filter { wateringProfile(for: $0) != nil && wateringSchedule(for: $0.id) == nil }
        guard !missing.isEmpty else { return true }
        let schedules = missing.compactMap { plant -> WateringSchedule? in
            guard let profile = wateringProfile(for: plant) else { return nil }
            return WateringSchedule.initial(
                for: plant,
                profile: profile,
                lastWatered: lastWatered(for: plant.id),
                now: now,
                reminderHour: garden.appPreferences.reminderHour,
                reminderMinute: garden.appPreferences.reminderMinute,
                calendar: calendar
            )
        }
        guard schedules.count == missing.count else { return false }
        return commit { garden in
            garden.wateringSchedules.append(contentsOf: schedules)
        }
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
