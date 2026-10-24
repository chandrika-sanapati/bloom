import Foundation
import Observation
import UserNotifications

enum Soil: String, Codable, CaseIterable, Identifiable {
    case dry = "Dry", damp = "Damp", unknown = "Not sure"
    var id: String { rawValue }
}

enum CareAction: String, Codable, CaseIterable, Identifiable {
    case watered = "Watered it", waited = "Didn't water", postponed = "Will check later"
    var id: String { rawValue }
    var short: String {
        switch self { case .watered: "Watered"; case .waited: "Waited"; case .postponed: "Check later" }
    }
}

enum PlantArea: String, Codable, CaseIterable, Identifiable {
    case whole = "Whole plant", leaves = "Leaves", stems = "Stems", flowers = "Flowers", fruits = "Fruits", pests = "Pests"
    var id: String { rawValue }
    var asset: String {
        switch self { case .whole: "area-whole"; case .leaves: "area-leaves"; case .stems: "area-stems"; case .flowers: "area-flowers"; case .fruits: "area-fruits"; case .pests: "area-pests" }
    }
    var subtitle: String {
        switch self { case .whole: "Shape, size, color"; case .leaves: "Texture, edges, spots"; case .stems: "Softness, color"; case .flowers: "Color, drop, timing"; case .fruits: "Size, color, drop"; case .pests: "Eggs, webs, insects" }
    }
    var observations: [String] {
        switch self {
        case .whole: ["No new growth", "Leaning or drooping", "Looks different", "Something else"]
        case .leaves: ["Dropping leaves", "Yellowing leaves", "Brown edges", "Spots or patches", "Curling or drooping", "Something else"]
        case .stems: ["Soft or mushy", "Changed color", "Leaning", "Something else"]
        case .flowers: ["Flowers aren't appearing", "Flowers dropping", "Changed color", "Something else"]
        case .fruits: ["Early fruit drop", "Changed color", "Spots or patches", "Something else"]
        case .pests: ["Visible insects", "Webs or eggs", "Sticky residue", "Something else"]
        }
    }
}

enum PlantReminderKind: String, Codable {
    case soilCheck, observation
}

enum CareTaskTiming: String, CaseIterable, Identifiable {
    case overdue = "Overdue", today = "Today", upcoming = "Upcoming"
    var id: Self { self }
    static func classify(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> Self {
        if date < now { return .overdue }
        return calendar.isDate(date, inSameDayAs: now) ? .today : .upcoming
    }
}

enum PlantPlacement: String, Codable, CaseIterable, Identifiable {
    case indoor = "Indoor", outdoor = "Outdoor"
    var id: String { rawValue }
}

enum InitialPlantStatus: String, Codable, CaseIterable, Identifiable {
    case lookingGood = "Looking good", needsAttention = "Needs a little attention", notSure = "Not sure yet"
    var id: String { rawValue }
    var symbol: String { switch self { case .lookingGood: "leaf"; case .needsAttention: "eye"; case .notSure: "questionmark" } }
    var detail: String { switch self { case .lookingGood: "Nothing unusual that I've noticed"; case .needsAttention: "Something looks different"; case .notSure: "I'm still getting to know this plant" } }
}

struct Plant: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var species: String
    var asset: String
    var location = ""
    var light = "Not sure"
    var drainage = "Not sure"
    var lastWatered: Date?
    var photo: Data?
    var reminder: Date?
    var reminderKind: PlantReminderKind?
    var placement: PlantPlacement?
    var initialStatus: InitialPlantStatus?
    var reminderObservationID: UUID?

    var referenceURL: URL? {
        let known = ["Dracaena trifasciata", "Monstera deliciosa", "Ficus elastica", "Epipremnum aureum"]
        guard known.contains(species) else { return nil }
        return URL(string: "https://en.wikipedia.org/wiki/" + species.replacingOccurrences(of: " ", with: "_"))
    }
}

struct CareRecord: Identifiable, Codable, Hashable {
    enum Kind: String, Codable { case check, change, followUp, careAction }
    var id = UUID()
    var plantID: UUID
    var date = Date()
    var kind: Kind
    var soil: Soil?
    var action: CareAction?
    var area: PlantArea?
    var observation = ""
    var firstNoticed = "Not sure"
    var lightChanged = "Not sure"
    var wateringContext = "I don't know"
    var note = ""
    var photo: Data?
    var parentID: UUID?
    var outcome = ""
    var assessment: PestAssessment?
    var leafAssessment: LeafAssessment?
    var planID: UUID?
    var planTaskID: UUID?
    var actionTitle: String?

    var title: String {
        switch kind { case .check: "Soil check"; case .change: observation; case .followUp: "Follow-up · \(outcome)"; case .careAction: actionTitle ?? "Care action" }
    }
    var summary: String {
        switch kind {
        case .check: "\(soil?.rawValue ?? "Not sure") · \(action?.rawValue ?? "No action recorded")"
        case .change: "\(area?.rawValue ?? "Whole plant") · First noticed: \(firstNoticed.lowercased())"
        case .followUp: observation
        case .careAction: action.map { "\(outcome) · \($0.rawValue)" } ?? outcome
        }
    }
}

struct Garden: Codable {
    var plants: [Plant] = []
    var records: [CareRecord] = []
    var hasStarted = false
    var isSample = false
    var sampleRevision: Int?
    var carePlans: [CarePlan]?
    var careTasks: [PlanTask]?
    var plantSearchPreferences: PlantSearchPreferences?
    var recentPlantSearches: [String]?
    var appPreferences: AppPreferences?
}

enum PlantCareLevel: String, CaseIterable {
    case easy = "Easy", moderate = "Moderate", hard = "Hard"
}

enum PlantLightNeed: String, CaseIterable {
    case low = "Low light", indirect = "Indirect light", partial = "Partial sun", full = "Full sun"
    var symbol: String { self == .low ? "sun.min" : "sun.max" }
}

struct PlantSpecies: Identifiable {
    var name: String
    var scientific: String
    var asset: String
    var care = PlantCareLevel.moderate
    var light = PlantLightNeed.indirect
    var id: String { name }
    static let catalog = [
        PlantSpecies(name: "Snake Plant", scientific: "Dracaena trifasciata", asset: "snake", care: .easy, light: .low),
        PlantSpecies(name: "Monstera", scientific: "Monstera deliciosa", asset: "monstera", care: .moderate, light: .indirect),
        PlantSpecies(name: "Rubber Plant", scientific: "Ficus elastica", asset: "rubber", care: .moderate, light: .indirect),
        PlantSpecies(name: "Pothos", scientific: "Epipremnum aureum", asset: "", care: .easy, light: .indirect)
    ]
}

struct CareSaveReceipt {
    let recordID: UUID
    let previousRecord: CareRecord?
    let previousPlant: Plant
    let completedReminder: Bool
}

@MainActor @Observable
final class BloomStore {
    private(set) var garden = Garden()
    var errorMessage: String?
    var careFeedback: CareFlowFeedback?
    private let fileURL: URL
    private var canSave = true
    private let managesNotifications: Bool
    private var planNotificationSync: Task<Void, Never>?
    let notificationClient: any BloomNotificationClient
    var notificationMessage: String?
    var allowsPlanNotifications: Bool { managesNotifications }

    init(fileURL: URL? = nil, managesNotifications: Bool = true, notificationClient: (any BloomNotificationClient)? = nil) {
        self.notificationClient = notificationClient ?? (ProcessInfo.processInfo.arguments.contains("--uitesting") ? PreviewBloomNotifications() : SystemBloomNotifications())
        self.managesNotifications = managesNotifications && !ProcessInfo.processInfo.arguments.contains("--uitesting") && (NSClassFromString("XCTestCase") == nil || notificationClient != nil)
        self.fileURL = fileURL ?? URL.applicationSupportDirectory.appending(path: "Bloom/garden.json")
        if ProcessInfo.processInfo.arguments.contains("--uitesting") {
            garden = Self.sampleGarden()
            if ProcessInfo.processInfo.arguments.contains("--uitesting-no-tasks") {
                for index in garden.plants.indices { garden.plants[index].reminder = nil; garden.plants[index].reminderKind = nil }
            }
            if ProcessInfo.processInfo.arguments.contains("--uitesting-no-activity") { garden.records = [] }
            self.canSave = false
            if ProcessInfo.processInfo.arguments.contains("--uitesting-search-location") {
                garden.plantSearchPreferences = PlantSearchPreferences(area: "Berlin", light: .unsure, location: .berlin)
            }
            if ProcessInfo.processInfo.arguments.contains("--uitesting-preferences") {
                garden.appPreferences = AppPreferences()
                garden.plantSearchPreferences = PlantSearchPreferences(area: "Berlin", light: .lower, location: .berlin, plantTypes: [.bushy, .trailing])
                garden.recentPlantSearches = ["Monstera", "Pothos"]
            }
            if ProcessInfo.processInfo.arguments.contains("--uitesting-leaf") {
                garden.plants[0].placement = .indoor
                let observation = CareRecord(plantID: garden.plants[0].id, kind: .change, area: .leaves, observation: "Dropping leaves", note: "Two leaves since yesterday")
                garden.records.insert(observation, at: 0)
            }
            if ProcessInfo.processInfo.arguments.contains("--uitesting-pest") || ProcessInfo.processInfo.arguments.contains("--uitesting-plan") || ProcessInfo.processInfo.arguments.contains("--uitesting-plan-review") {
                let observation = CareRecord(plantID: garden.plants[0].id, kind: .change, area: .pests, observation: "Visible insects")
                garden.records.insert(observation, at: 0)
                if !ProcessInfo.processInfo.arguments.contains("--uitesting-pest") {
                    let answers = PestAssessment(signs: .cotton, location: .joints, extent: .few, placement: .indoor)
                    if let id = startCarePlan(observationID: observation.id, answers: answers, reviewDays: 7), ProcessInfo.processInfo.arguments.contains("--uitesting-plan-review") {
                        for task in tasks(for: id) where task.step != .review { _ = finishPlanAction(taskID: task.id) }
                    }
                }
            }
        } else if FileManager.default.fileExists(atPath: self.fileURL.path) {
            do {
                garden = try JSONDecoder().decode(Garden.self, from: Data(contentsOf: self.fileURL))
                if let upgraded = Self.upgradeSample(garden) { _ = commit { $0 = upgraded } }
            }
            catch {
                canSave = false
                errorMessage = "Your saved garden couldn't be opened. The original file has been preserved. Close Bloom and recover the garden file before continuing."
            }
        }
    }

    @discardableResult
    func commit(_ update: (inout Garden) -> Void) -> Bool {
        if !canSave && !ProcessInfo.processInfo.arguments.contains("--uitesting") { return false }
        var next = garden
        update(&next)
        if canSave {
            do {
                try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                try JSONEncoder().encode(next).write(to: fileURL, options: .atomic)
            } catch { errorMessage = "\(error.localizedDescription) Your previous records are safe. Please try again."; return false }
        }
        garden = next
        refreshPlanTaskNotifications()
        return true
    }

    func refreshPlanTaskNotifications() {
        guard managesNotifications else { return }
        let previous = planNotificationSync
        planNotificationSync = Task { [weak self] in
            await previous?.value
            await self?.syncPlanTaskNotifications()
        }
    }

    func waitForNotificationSync() async { await planNotificationSync?.value }

    func start(sample: Bool) -> Bool {
        commit { garden in
            garden = sample ? Self.sampleGarden() : Garden(hasStarted: true)
            garden.appPreferences = AppPreferences()
        }
    }
    func plant(_ id: UUID) -> Plant? { garden.plants.first { $0.id == id } }
    func record(_ id: UUID) -> CareRecord? { garden.records.first { $0.id == id } }
    func records(for plantID: UUID) -> [CareRecord] { garden.records.filter { $0.plantID == plantID }.sorted { $0.date > $1.date } }
    func latestCheck(for plantID: UUID) -> CareRecord? { records(for: plantID).first { $0.kind == .check } }
    func status(for plant: Plant) -> String { latestCheck(for: plant.id)?.summary ?? "Not checked yet" }

    func savePlant(_ plant: Plant) -> Bool {
        commit { garden in
            if let i = garden.plants.firstIndex(where: { $0.id == plant.id }) { garden.plants[i] = plant }
            else { garden.plants.append(plant) }
        }
    }
    /// Save the whole setup at once, so closing the flow never leaves a partial plant.
    func addPlant(_ plant: Plant, placement: PlantPlacement, status: InitialPlantStatus?) -> Bool {
        var ready = plant
        ready.name = ready.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !ready.name.isEmpty else { return false }
        ready.placement = placement
        ready.initialStatus = status
        return savePlant(ready)
    }
    func deletePlant(_ id: UUID) -> Bool {
        let hadReminder = plant(id)?.reminder != nil
        let saved = commit {
            $0.plants.removeAll { $0.id == id }; $0.records.removeAll { $0.plantID == id }
            $0.carePlans?.removeAll { $0.plantID == id }; $0.careTasks?.removeAll { $0.plantID == id }
        }
        if saved && hadReminder && managesNotifications { notificationClient.remove([id.uuidString]) }
        return saved
    }
    func saveRecord(_ record: CareRecord) -> Bool {
        guard plant(record.plantID) != nil else { return false }
        let priorConcern = records(for: record.plantID).first { $0.kind == .change }?.id
        let isNewObservation = record.kind == .change && self.record(record.id) == nil
        return commit { garden in
            if isNewObservation, let p = garden.plants.firstIndex(where: { $0.id == record.plantID }), garden.plants[p].reminderKind == .observation, garden.plants[p].reminderObservationID == nil {
                garden.plants[p].reminderObservationID = priorConcern
            }
            if let i = garden.records.firstIndex(where: { $0.id == record.id }) { garden.records[i] = record }
            else { garden.records.insert(record, at: 0) }
        }
    }
    func deleteRecord(_ id: UUID) -> Bool {
        guard record(id)?.planTaskID == nil else { return false }
        let before = garden.plants.filter { $0.reminder != nil }.map(\.id)
        let success = commit { $0.removeCareRecords(startingAt: id) }
        if success && managesNotifications {
            notificationClient.remove(before.filter { plant($0)?.reminder == nil }.map(\.uuidString))
        }
        return success
    }
    func wateredDate(for plant: Plant) -> Date? {
        let logged = records(for: plant.id).filter { $0.action == .watered }.map(\.date).max()
        return [plant.lastWatered, logged].compactMap { $0 }.max()
    }
    /// A new observation and the matching task completion are one durable change.
    func finishCare(_ record: CareRecord) async -> CareSaveReceipt? {
        guard let previousPlant = plant(record.plantID) else { return nil }
        let expectedKind: PlantReminderKind = record.kind == .check ? .soilCheck : .observation
        let correctObservation = expectedKind != .observation || previousPlant.reminderObservationID == nil || previousPlant.reminderObservationID == record.parentID
        let completes = record.kind != .change && previousPlant.reminder != nil && (previousPlant.reminderKind ?? .soilCheck) == expectedKind && correctObservation
        let priorConcern = records(for: record.plantID).first { $0.kind == .change }?.id
        let previousRecord = self.record(record.id)
        guard commit({ garden in
            if let index = garden.records.firstIndex(where: { $0.id == record.id }) { garden.records[index] = record }
            else { garden.records.insert(record, at: 0) }
            if let index = garden.plants.firstIndex(where: { $0.id == record.plantID }) {
                if record.kind == .change && garden.plants[index].reminderKind == .observation && garden.plants[index].reminderObservationID == nil { garden.plants[index].reminderObservationID = priorConcern }
                if completes { garden.plants[index].reminder = nil; garden.plants[index].reminderKind = nil; garden.plants[index].reminderObservationID = nil }
            }
        }) else { return nil }
        if completes && managesNotifications { notificationClient.remove([record.plantID.uuidString]) }
        return CareSaveReceipt(recordID: record.id, previousRecord: previousRecord, previousPlant: previousPlant, completedReminder: completes)
    }

    func undoCare(_ receipt: CareSaveReceipt) async -> Bool {
        guard let current = plant(receipt.previousPlant.id) else { return false }
        // Keep any new reminder the user explicitly chose after saving.
        let restoreReminder = receipt.completedReminder && current.reminder == nil
        guard commit({ garden in
            if receipt.previousRecord == nil { garden.removeCareRecords(startingAt: receipt.recordID) }
            else { garden.records.removeAll { $0.id == receipt.recordID } }
            if let previous = receipt.previousRecord { garden.records.insert(previous, at: 0) }
            if restoreReminder, let index = garden.plants.firstIndex(where: { $0.id == current.id }) {
                garden.plants[index].reminder = receipt.previousPlant.reminder
                garden.plants[index].reminderKind = receipt.previousPlant.reminderKind
                garden.plants[index].reminderObservationID = receipt.previousPlant.reminderObservationID
            }
        }) else { return false }

        return true
    }

    func setReminder(for plantID: UUID, days: Int?, kind: PlantReminderKind = .soilCheck, observationID: UUID? = nil) async -> String? {
        await setReminder(for: plantID, date: days.map { newReminderDate(days: $0) }, kind: kind, observationID: observationID)
    }

    func setReminder(for plantID: UUID, date: Date?, kind: PlantReminderKind = .soilCheck, observationID: UUID? = nil) async -> String? {
        guard var plant = plant(plantID) else { return "This plant is no longer in your garden." }
        if let date, date <= Date() { return "Choose a future date and time." }
        plant.reminder = date; plant.reminderKind = date == nil ? nil : kind
        plant.reminderObservationID = date == nil || kind != .observation ? nil : (observationID ?? plant.reminderObservationID ?? records(for: plantID).first { $0.kind == .change }?.id)
        guard savePlant(plant) else { return "The reminder couldn't be saved. Please try again." }
        // Dates belong to tasks. Alerts are a separate, optional app preference.
        if managesNotifications { await waitForNotificationSync() }
        return nil
    }

    static func sampleGarden() -> Garden {
        let snake = Plant(name: "Snake Plant", species: "Dracaena trifasciata", asset: "snake", location: "Living room", light: "Indirect light", drainage: "Yes")
        let monstera = Plant(name: "Monstera", species: "Monstera deliciosa", asset: "monstera", location: "By the window", light: "Indirect light", drainage: "Yes", reminder: Date().addingTimeInterval(86400), reminderKind: .soilCheck)
        let rubber = Plant(name: "Rubber Plant", species: "Ficus elastica", asset: "rubber", location: "Bedroom")
        let office = Plant(name: "Office Snake", species: "Dracaena trifasciata", asset: "area-whole", location: "Workspace", light: "Indirect light", reminder: Date().addingTimeInterval(172800), reminderKind: .observation)
        let kitchen = Plant(name: "Kitchen Monstera", species: "Monstera deliciosa", asset: "monstera", location: "Kitchen", placement: .indoor, initialStatus: .lookingGood)
        let change = CareRecord(plantID: office.id, date: Date().addingTimeInterval(-259200), kind: .change, area: .whole, observation: "No new growth", firstNoticed: "Recently", note: "Sample observation: keeping a record to compare next time.")
        return Garden(plants: [snake, monstera, rubber, office, kitchen], records: [
            CareRecord(plantID: snake.id, date: Date().addingTimeInterval(-7200), kind: .check, soil: .damp, action: .waited, note: "The soil still feels damp below the surface."),
            CareRecord(plantID: monstera.id, date: Date().addingTimeInterval(-14400), kind: .check, soil: .dry, action: .watered, note: "Sample activity: watered after checking the soil."),
            CareRecord(plantID: rubber.id, date: Date().addingTimeInterval(-86400), kind: .check, soil: .unknown, action: .postponed),
            CareRecord(plantID: office.id, date: Date().addingTimeInterval(-90000), kind: .followUp, observation: change.observation, parentID: change.id, outcome: "About the same"),
            change
        ], hasStarted: true, isSample: true, sampleRevision: 3)
    }

    static func upgradeSample(_ old: Garden) -> Garden? {
        guard old.isSample, (old.sampleRevision ?? 0) < 3 else { return nil }
        var next = old
        next.sampleRevision = 3
        // Only expand a recognizable legacy demo; never repopulate a real garden.
        guard ["snake", "monstera", "rubber"].allSatisfy({ asset in old.plants.contains { $0.asset == asset } }) else { return next }
        if !next.plants.contains(where: { $0.asset == "area-whole" }) { next.plants.append(sampleGarden().plants[3]) }
        if !next.plants.contains(where: { $0.name == "Kitchen Monstera" }) { next.plants.append(sampleGarden().plants[4]) }
        if let i = next.plants.firstIndex(where: { $0.asset == "monstera" }), next.plants[i].reminder == nil {
            next.plants[i].reminder = Date().addingTimeInterval(86400)
            next.plants[i].reminderKind = .soilCheck
        }
        for asset in ["monstera", "rubber"] where next.records.count < 5 {
            if let plant = next.plants.first(where: { $0.asset == asset }) {
                next.records.append(CareRecord(plantID: plant.id, date: Date().addingTimeInterval(asset == "monstera" ? -14400 : -86400), kind: .check, soil: asset == "monstera" ? .dry : .unknown, action: asset == "monstera" ? .watered : .postponed, note: "Sample activity added with the updated demo garden."))
            }
        }
        return next
    }
}
