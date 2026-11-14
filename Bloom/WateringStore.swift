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
}
