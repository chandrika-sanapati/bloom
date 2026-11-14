import Foundation
import Observation

enum Soil: String, Codable, CaseIterable, Identifiable {
    case dry = "Dry"
    case damp = "Damp"
    case unknown = "Not sure"
    var id: String { rawValue }
}

enum WateringOutcome: String, Codable, CaseIterable, Identifiable {
    case watered = "Watered"
    case checkedNotWatered = "Checked — not watered"
    var id: String { rawValue }
}

enum CareTaskTiming: String, CaseIterable, Identifiable {
    case overdue = "Overdue"
    case today = "Today"
    case upcoming = "Upcoming"
    var id: Self { self }

    static func classify(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> Self {
        if date < now { return .overdue }
        return calendar.isDate(date, inSameDayAs: now) ? .today : .upcoming
    }
}

struct Plant: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var species: String
    var asset: String
    var photo: Data?

    var displayName: String { name }
}

struct WateringRecord: Identifiable, Codable, Hashable {
    var id = UUID()
    var plantID: UUID
    var scheduledFor: Date
    var recordedAt: Date
    var outcome: WateringOutcome
    var soil: Soil
    var note = ""
}

struct AppPreferences: Codable, Equatable {
    var reminderHour = 9
    var reminderMinute = 0
    var taskNotifications = false
}

struct Garden: Codable {
    var plants: [Plant] = []
    var wateringSchedules: [WateringSchedule] = []
    var wateringRecords: [WateringRecord] = []
    var hasStarted = false
    var appPreferences = AppPreferences()
}

enum PlantCareLevel: String, CaseIterable {
    case easy = "Easy"
    case moderate = "Moderate"
    case hard = "Hard"
}

enum PlantLightNeed: String, CaseIterable {
    case low = "Low light"
    case indirect = "Indirect light"
}

struct PlantSpecies: Identifiable, Hashable {
    var name: String
    var scientific: String
    var asset: String
    var care: PlantCareLevel = .moderate
    var light: PlantLightNeed = .indirect
    var id: String { scientific }

    static let catalog = [
        PlantSpecies(name: "Snake Plant", scientific: "Dracaena trifasciata", asset: "snake", care: .easy, light: .low),
        PlantSpecies(name: "Monstera", scientific: "Monstera deliciosa", asset: "monstera"),
        PlantSpecies(name: "Rubber Plant", scientific: "Ficus elastica", asset: "rubber"),
        PlantSpecies(name: "Pothos", scientific: "Epipremnum aureum", asset: "pothos", care: .easy)
    ]
}

@MainActor @Observable
final class BloomStore {
    private(set) var garden: Garden
    var errorMessage: String?
    private let fileURL: URL

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? URL.applicationSupportDirectory.appending(path: "Bloom/garden.json")
        if let data = try? Data(contentsOf: self.fileURL), let saved = try? JSONDecoder().decode(Garden.self, from: data) {
            garden = saved
        } else {
            garden = Garden()
        }
    }

    @discardableResult
    func commit(_ update: (inout Garden) -> Void) -> Bool {
        var next = garden
        update(&next)
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(next).write(to: fileURL, options: .atomic)
            garden = next
            return true
        } catch {
            errorMessage = "Your changes couldn't be saved. Your previous records are safe."
            return false
        }
    }

    func plant(_ id: UUID) -> Plant? { garden.plants.first { $0.id == id } }
    func schedule(_ plantID: UUID) -> WateringSchedule? { garden.wateringSchedules.first { $0.plantID == plantID } }
    func records(for plantID: UUID) -> [WateringRecord] { garden.wateringRecords.filter { $0.plantID == plantID }.sorted { $0.recordedAt > $1.recordedAt } }
    func lastWatered(for plantID: UUID) -> Date? { records(for: plantID).first(where: { $0.outcome == .watered })?.recordedAt }

    @discardableResult
    func start() -> Bool { commit { $0.hasStarted = true } }

    @discardableResult
    func addPlant(_ plant: Plant) -> Bool {
        guard !plant.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard commit({ $0.plants.append(plant) }) else { return false }
        _ = ensureWateringSchedule(for: plant.id)
        return true
    }

    @discardableResult
    func savePlant(_ plant: Plant) -> Bool {
        commit { garden in
            if let index = garden.plants.firstIndex(where: { $0.id == plant.id }) { garden.plants[index] = plant }
            else { garden.plants.append(plant) }
        }
    }

    @discardableResult
    func deletePlant(_ id: UUID) -> Bool {
        commit { garden in
            garden.plants.removeAll { $0.id == id }
            garden.wateringSchedules.removeAll { $0.plantID == id }
            garden.wateringRecords.removeAll { $0.plantID == id }
        }
    }
}
