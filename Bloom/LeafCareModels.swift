import Foundation

enum LeafSoil: String, Codable, CaseIterable, Identifiable {
    case dry = "Dry below the surface", moist = "Moist, not soggy", soggy = "Soggy or standing in water", unsure = "Not sure yet"
    var id: Self { self }
}
enum LeafDrainage: String, Codable, CaseIterable, Identifiable {
    case yes = "Yes, water can drain out", no = "No drainage holes", unsure = "Not sure yet"
    var id: Self { self }
}
enum LeafEnvironmentChange: String, Codable, CaseIterable, Identifiable {
    case yes = "Yes, conditions changed", no = "No recent change", unsure = "Not sure yet"
    var id: Self { self }
}
enum LeafWarning: String, Codable, CaseIterable, Identifiable {
    case none = "None of these", soft = "Soft or blackened stems/base", rapid = "Rapid decline or heavy leaf loss", pests = "Insects, clusters, or webbing", unsure = "Not sure yet"
    var id: Self { self }
}

struct LeafAssessment: Codable, Hashable {
    var soil: LeafSoil?
    var drainage: LeafDrainage?
    var environment: LeafEnvironmentChange?
    var warning: LeafWarning?
    var placement: AssessmentPlacement?
    var complete: Bool { soil != nil && drainage != nil && environment != nil && warning != nil && placement != nil }

    func recommendation(for observation: CareRecord, plant: Plant) -> CarePlanKind {
        if warning == .soft || warning == .rapid || (observation.area == .stems && observation.observation == "Soft or mushy") { return .leafExpert }
        // Only evidence needed for an action is required; unanswered fields stay unknown.
        let knownPlacement = placement ?? plant.placement.map { $0 == .indoor ? .indoor : .outdoor }
        guard knownPlacement == .indoor, warning == LeafWarning.none else { return .leafInspection }
        let supportedSymptom = observation.area == .leaves && ["Dropping leaves", "Curling or drooping", "Yellowing leaves", "Brown edges"].contains(observation.observation)
            || observation.area == .whole && observation.observation == "Leaning or drooping"
        let knownSpecies = PlantSpecies.catalog.contains { !$0.scientific.isEmpty && $0.scientific == plant.species }
        guard supportedSymptom && knownSpecies else { return .leafInspection }
        if soil == .soggy { return .leafWet }
        if soil == .dry && drainage == .yes { return .leafDry }
        if (soil == .moist || soil == nil || soil == .unsure) && environment == .yes { return .leafEnvironment }
        return .leafInspection
    }

    var summary: [(String, String)] {
        [("Soil now", soil?.rawValue ?? "Not checked"), ("Drainage", drainage?.rawValue ?? "Not checked"),
         ("Recent conditions", environment?.rawValue ?? "Not checked"), ("Other signs", warning?.rawValue ?? "Not checked"),
         ("Placement", placement?.rawValue ?? "Not checked")]
    }
}

extension CarePlanKind {
    var isLeafGuidance: Bool {
        switch self { case .leafDry, .leafWet, .leafEnvironment, .leafInspection, .leafExpert: true; default: false }
    }
    var needsSpecialist: Bool { self == .expert || self == .leafExpert }
    var leafTitle: String {
        switch self {
        case .leafDry: "Check dry roots before watering"
        case .leafWet: "Let excess water drain"
        case .leafEnvironment: "Give your plant steady conditions"
        case .leafExpert: "Get help before waiting"
        default: "Check the cause before treating"
        }
    }
    var leafExplanation: String {
        switch self {
        case .leafDry: "You found dry potting mix and drainage. Lack of water may be contributing, but leaf symptoms alone don't confirm it. Check this plant's moisture needs before giving one thorough watering."
        case .leafWet: "You found soggy mix or standing water. Wet roots can also cause wilting and leaf loss. Drain excess water and check moisture before adding more; this doesn't confirm root rot."
        case .leafEnvironment: "The mix is moist and conditions recently changed. Light, heat or cold may be contributing. Check the plant's preferred conditions and avoid repeated moves while watching for new damage."
        case .leafExpert: "Rapid decline or a soft, dark base needs a closer assessment. Get plant-care help promptly rather than waiting three days or trying a watering treatment by guesswork."
        default: "Water balance, growing conditions, pests and normal older-leaf loss can look similar. These checks don't support a specific treatment yet. Gather clearer evidence and check this plant's growing needs first."
        }
    }
    var leafImprovement: String {
        "Compare leaf firmness and new leaf loss with your starting observation. Note whether the mix is still dry, moist or soggy. Fallen leaves won't reattach, and brown tissue won't turn green again. Three days is a first check, not proof of recovery. If decline is rapid or stems soften, get help sooner."
    }
    var otherLeafCauses: [String] {
        switch self {
        case .leafDry: ["Too much water can cause similar wilting.", "Light, temperature changes or pests may also contribute."]
        case .leafWet: ["Leaf symptoms alone can't identify damaged roots.", "Changes in light, temperature or pests can also affect leaves."]
        default: ["Too much or too little water can affect leaf firmness and loss.", "Check recent light/temperature changes, pests and whether only older leaves are affected."]
        }
    }
}

extension CarePlanStep {
    var leafInstructions: [String] {
        switch self {
        case .checkSoilMoisture: ["Feel the mix below the surface and compare it with this plant's moisture needs. Don't add water while its needs are unclear."]
        case .checkGrowingConditions: ["Check the plant's light and temperature needs. Note recent moves, draughts, heaters or strong direct sun."]
        case .checkLeafChanges: ["Inspect older and newer leaves, including their undersides. Note new damage, visible insects or webbing. Save a comparison photo if helpful.", "If the plant declines quickly or stems soften, seek plant-care help sooner."]
        case .waterDryRoots: [
            "Check moisture a little below the surface and compare it with your plant's needs. A dry top alone isn't enough; Snake Plants need the mix to dry between waterings.",
            "If the root-zone mix is dry enough for this plant, water the mix thoroughly once and let excess water escape through the drainage holes. Empty the saucer or outer pot.",
            "Recheck moisture before watering again. The progress-check date is not a repeat-watering date. If you're unsure, pause and use the inspection or specialist option."
        ]
        case .drainExcessWater: [
            "Empty standing water from the saucer or decorative outer pot. Let a nursery pot drain freely; keep the plant safely supported.",
            "Check that drainage holes are clear. Let the mix reach the moisture level appropriate for this plant before watering again.",
            "Avoid adding water just because leaves droop. If the base or stems are soft/dark, or decline continues quickly, ask a specialist rather than waiting for the check-in."
        ]
        case .steadyConditions: [
            "Check the plant's label or a species-specific guide for its light and temperature needs.",
            "Choose a suitable stable spot away from cold draughts, heaters and damaging direct sun. Avoid sudden large changes in light.",
            "Keep checking the mix before watering. Photograph or note new leaf loss so you can compare the same area at your check-in."
        ]
        default: [
            "Check the potting mix below the surface, drainage, and your plant's own moisture needs. Don't add water while its needs are unclear.",
            "Look at older versus newer leaves, undersides and stems. Note insects, webbing, soft tissue, recent moves or temperature changes.",
            "Keep a close-up and whole-plant photo if helpful. If signs worsen quickly or stems soften, seek plant-care help sooner."
        ]
        }
    }
}

extension PlanOutcome {
    func title(for kind: CarePlanKind) -> String {
        guard kind.isLeafGuidance else { return rawValue }
        return switch self {
        case .fewer: "Less drooping or leaf loss"
        case .same: "About the same"
        case .worse: "More drooping or new damage"
        case .unclear: "Not sure yet"
        case .none: "No new concerning changes"
        }
    }
    static func fromStored(_ value: String?) -> Self? {
        guard let value else { return nil }
        return Self(rawValue: value) ?? allCases.first { $0.title(for: .leafInspection) == value }
    }
}

enum LeafCareSources {
    static let sources = [
        ("RHS · Helping a poorly houseplant", "https://www.rhs.org.uk/plants/types/houseplants/how-to-help-a-poorly-houseplant"),
        ("RHS · Leaf damage and possible causes", "https://www.rhs.org.uk/prevention-protection/leaf-damage-on-houseplants"),
        ("University of Maryland · Indoor plant problems", "https://extension.umd.edu/resource/diagnose-indoor-plant-problems"),
        ("RHS · Check moisture before watering", "https://www.rhs.org.uk/advice/understanding-plants/how-plants-absorb-water"),
        ("RHS · Snake plant watering", "https://www.rhs.org.uk/plants/sansevieria/growing-guide")
    ]
}

enum ObservationGuidanceRoute {
    static func usesVisualEntry(_ observation: CareRecord, replacing plan: CarePlan? = nil) -> Bool {
        isLeaf(observation, replacing: plan) || (observation.area == .pests && observation.assessment == nil && plan?.assessment == nil)
    }
    static func isLeaf(_ observation: CareRecord, replacing plan: CarePlan? = nil) -> Bool {
        if let plan { return plan.kind.isLeafGuidance }
        if observation.area == .pests { return false }
        // Keep a previously saved V1 pest assessment resumable.
        if observation.assessment != nil && observation.leafAssessment == nil { return false }
        return true
    }
}
