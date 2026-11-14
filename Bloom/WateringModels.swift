import Foundation

struct WateringProfile: Identifiable, Hashable {
    let id: String
    let displayName: String
    let scientificName: String
    let rangeDays: ClosedRange<Int>
    let startingIntervalDays: Int
    let careCue: String

    static let supported: [WateringProfile] = [
        WateringProfile(
            id: "Dracaena trifasciata",
            displayName: "Snake Plant",
            scientificName: "Dracaena trifasciata",
            rangeDays: 14...30,
            startingIntervalDays: 21,
            careCue: "Let the growing medium dry substantially before watering."
        ),
        WateringProfile(
            id: "Monstera deliciosa",
            displayName: "Monstera",
            scientificName: "Monstera deliciosa",
            rangeDays: 7...14,
            startingIntervalDays: 10,
            careCue: "Check the top 1–2 inches of soil and avoid waterlogging."
        ),
        WateringProfile(
            id: "Ficus elastica",
            displayName: "Rubber Plant",
            scientificName: "Ficus elastica",
            rangeDays: 7...21,
            startingIntervalDays: 14,
            careCue: "Use a free-draining medium and check before watering."
        ),
        WateringProfile(
            id: "Epipremnum aureum",
            displayName: "Pothos",
            scientificName: "Epipremnum aureum",
            rangeDays: 7...21,
            startingIntervalDays: 14,
            careCue: "Allow the soil to dry between checks; avoid keeping it constantly wet."
        )
    ]

    static func forPlant(_ plant: Plant) -> WateringProfile? {
        let scientific = plant.species.trimmingCharacters(in: .whitespacesAndNewlines)
        if let match = supported.first(where: { $0.scientificName.caseInsensitiveCompare(scientific) == .orderedSame }) {
            return match
        }
        return supported.first { $0.displayName.caseInsensitiveCompare(plant.displayName) == .orderedSame }
    }
}

struct WateringSchedule: Identifiable, Codable, Hashable {
    var id = UUID()
    var plantID: UUID
    var profileID: String
    var profileRangeLowerDays: Int
    var profileRangeUpperDays: Int
    var profileIntervalDays: Int
    var nextCheckAt: Date
    var createdAt: Date
    var updatedAt: Date
    var defaultReminderHour: Int
    var defaultReminderMinute: Int

    var profileRange: ClosedRange<Int> { profileRangeLowerDays...profileRangeUpperDays }

    static func initial(
        for plant: Plant,
        profile: WateringProfile,
        lastWatered: Date?,
        now: Date,
        reminderHour: Int,
        reminderMinute: Int,
        calendar: Calendar
    ) -> WateringSchedule {
        let next: Date
        if let lastWatered {
            let base = calendar.date(byAdding: .day, value: profile.startingIntervalDays, to: lastWatered) ?? lastWatered
            next = calendar.date(bySettingHour: reminderHour, minute: reminderMinute, second: 0, of: base) ?? base
        } else {
            next = calendar.date(bySettingHour: reminderHour, minute: reminderMinute, second: 0, of: now) ?? now
        }
        return WateringSchedule(
            plantID: plant.id,
            profileID: profile.id,
            profileRangeLowerDays: profile.rangeDays.lowerBound,
            profileRangeUpperDays: profile.rangeDays.upperBound,
            profileIntervalDays: profile.startingIntervalDays,
            nextCheckAt: next,
            createdAt: now,
            updatedAt: now,
            defaultReminderHour: reminderHour,
            defaultReminderMinute: reminderMinute
        )
    }
}

enum WateringScheduleSource: String, Codable {
    case plantType
}
