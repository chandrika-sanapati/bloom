import Foundation

enum PestSigns: String, Codable, CaseIterable, Identifiable {
    case cotton = "White cotton-like clusters", webbing = "Fine webbing", insects = "Other visible insects", none = "No visible pests", unsure = "Not sure"
    var id: Self { self }
}
enum PestLocation: String, Codable, CaseIterable, Identifiable {
    case joints = "Where leaves join stems", leaves = "Leaves or stems", soil = "Only in the soil", unsure = "Not sure"
    var id: Self { self }
}
enum PestExtent: String, Codable, CaseIterable, Identifiable {
    case few = "A small, reachable area", widespread = "Several areas or heavy damage", unsure = "Not sure"
    var id: Self { self }
}
enum AssessmentPlacement: String, Codable, CaseIterable, Identifiable {
    case indoor = "Indoors", outdoor = "Outdoors", unsure = "Not sure"
    var id: Self { self }
}
struct PestAssessment: Codable, Hashable {
    var signs: PestSigns?
    var location: PestLocation?
    var extent: PestExtent?
    var placement: AssessmentPlacement?
    var complete: Bool { signs != nil && location != nil && extent != nil && placement != nil }
    var recommendation: CarePlanKind {
        guard complete else { return .inspection }
        if extent == .widespread { return .expert }
        if placement == .indoor && signs == .cotton && (location == .joints || location == .leaves) && extent == .few { return .mealybugs }
        return .inspection
    }
}
enum CarePlanKind: String, Codable {
    case mealybugs, inspection, expert
    var title: String { switch self { case .mealybugs: "Possible mealybugs"; case .inspection: "Look a little closer"; case .expert: "Get help identifying the cause" } }
    var explanation: String {
        switch self {
        case .mealybugs: "Cotton-like clusters on indoor leaves or stems can be a sign of mealybugs. Your answers fit this possibility, but this is not a confirmed identification. Start with containment and careful physical removal in the small area you described."
        case .inspection: "These answers don't establish a mealybug problem. A closer inspection can help you choose an appropriate next step. Avoid treating an unidentified problem with a spray."
        case .expert: "You described several affected areas or heavy damage. A small-area removal plan may not be enough. Keep a record and get plant-care help to identify the cause and choose an appropriate treatment."
        }
    }
    var defaultReviewDays: Int { self == .mealybugs ? 7 : 3 }
    var actionSteps: [CarePlanStep] {
        switch self {
        case .mealybugs: [.separate, .removeBugs]
        case .inspection: [.inspect]
        case .expert: [.inspect, .askExpert]
        }
    }
    var improvement: String {
        switch self {
        case .mealybugs: "Compare the number of visible clusters, whether new areas are affected, and any new damage. Fewer visible signs are encouraging; one check does not prove the pest is gone."
        case .inspection: "Look for a clearer pattern: where the change appears, whether it spreads, and any visible pests. New evidence can help you reassess the plan."
        case .expert: "Compare any new damage and record the advice you receive. Reassess before starting a treatment that depends on identifying the cause."
        }
    }
}
enum CarePlanStep: String, Codable {
    case separate, removeBugs, inspect, askExpert, review
    var title: String {
        switch self { case .separate: "Keep this plant separate"; case .removeBugs: "Remove visible mealybugs"; case .inspect: "Inspect the affected area"; case .askExpert: "Ask a plant-care specialist"; case .review: "Check the plan's progress" }
    }
    var instructions: [String] {
        switch self {
        case .separate: ["Move the plant away from other plants, while keeping suitable light and growing conditions.", "Inspect nearby plants, including leaf undersides and where leaves meet stems.", "Keep tools used on this plant separate or clean them before using them elsewhere."]
        case .removeBugs: ["In good light, check that you can see individual cottony insects rather than a mark on the leaf.", "Use tweezers to gently lift off reachable mealybugs. Support the leaf or stem and avoid scraping or tearing plant tissue.", "Stop if insects are difficult to reach, the area is fragile, or damage is extensive. Ask for plant-care help instead.", "This first plan does not include a spray or homemade alcohol/soap mixture."]
        case .inspect: ["Look closely at the same area as your saved observation, under similar light.", "Check leaf undersides, leaf joints, stems, and the pot for visible insects, clusters, or webbing.", "Take a close-up and a whole-plant photo if you can. Note which areas are affected.", "If you find pests, keep the plant away from other plants while you identify them."]
        case .askExpert: ["Bring your original observation, a whole-plant photo, a close-up, and recent care notes to a plant-care specialist or garden centre.", "Ask them to identify the cause before choosing a treatment. Mention any actions you have already taken.", "Record their advice in your task note. Bloom will not automatically recommend a stronger product."]
        case .review: ["Compare the original observation with the plant now.", "Look at new damage and visible signs, and consider which actions were actually completed.", "Record a photo or note if helpful. You can reassess the approach if things are unclear or worse."]
        }
    }
    var materials: String {
        switch self { case .separate: "A suitable place away from other plants"; case .removeBugs: "Tweezers, good light, and a way to collect removed insects"; case .inspect: "Good light; an optional magnifier and camera"; case .askExpert: "Your observation, photos, and care notes"; case .review: "Your original observation and action record" }
    }
}
enum CarePlanStatus: String, Codable { case active = "In progress", needsReview = "Needs another look", resolved = "Resolved", stopped = "Stopped" }
struct CarePlan: Identifiable, Codable, Hashable {
    var id = UUID()
    var plantID: UUID
    var observationID: UUID
    var createdAt = Date()
    var kind: CarePlanKind
    var assessment: PestAssessment
    var baseline: CareRecord
    var status = CarePlanStatus.active
    var reviewAfterDays: Int?
    var guidanceVersion = "2026-10-19.1"
}
enum PlanTaskStatus: String, Codable { case waiting = "After your actions", pending = "To do", completed = "Done", skipped = "Skipped", cancelled = "Cancelled" }
struct PlanTask: Identifiable, Codable, Hashable {
    var id = UUID()
    var plantID: UUID
    var planID: UUID
    var step: CarePlanStep
    var position: Int
    var status = PlanTaskStatus.pending
    var due: Date?
    var completedAt: Date?
    var customDate = false
    var notifications = false
    var isOpen: Bool { status == .pending || status == .waiting }
}
enum PlanOutcome: String, Codable, CaseIterable, Identifiable {
    case fewer = "Fewer visible signs", same = "About the same", worse = "More signs or new damage", unclear = "Not sure yet", none = "No visible signs now"
    var id: Self { self }
}
struct PlanTaskReceipt {
    let task: PlanTask
    let previousStatus: CarePlanStatus
    let recordID: UUID
}
struct PlanTaskRoute: Identifiable { let id: UUID }

enum CareGuidanceSources {
    static let sources: [(String, String)] = [
        ("University of Minnesota · Indoor plant pests", "https://extension.umn.edu/garden-and-home/yard-and-garden/yard-and-garden-insects/insects-on-indoor-plants"),
        ("University of Maryland · Mealybugs", "https://extension.umd.edu/resource/mealybugs-indoor-plants")
    ]
}
