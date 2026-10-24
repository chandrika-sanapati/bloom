import SwiftUI

/// Keep disabled actions visible without suggesting they can be activated.
struct BloomPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(BloomType.section)
            .foregroundStyle(isEnabled ? Color.white : Color(uiColor: .secondaryLabel))
            .padding(.horizontal, 18).padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(isEnabled ? BloomTheme.teal : Color(uiColor: .systemGray5),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(configuration.isPressed && isEnabled ? 0.86 : 1)
            .scaleEffect(configuration.isPressed && isEnabled && !reduceMotion ? 0.98 : 1)
            .animation(reduceMotion ? nil : BloomTheme.spring, value: configuration.isPressed)
    }
}

struct BloomPrimaryAction: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity)
        }.buttonStyle(BloomPrimaryButtonStyle())
    }
}

struct BloomActionRow: View {
    let title: String
    var body: some View {
        HStack(spacing: 12) {
            Text(title).font(BloomType.section)
            Spacer(minLength: 8)
            BloomSymbol(name: "chevron.right", compact: true)
        }.foregroundStyle(BloomTheme.teal)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
    }
}

extension View {
    func bloomNativeForm() -> some View {
        scrollContentBackground(.hidden).background(BloomTheme.canvas)
            .headerProminence(.increased).textCase(nil)
    }
    func bloomNativeFooter<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        safeAreaInset(edge: .bottom) { content().padding(.horizontal, 20).padding(.vertical, 12).background(.bar) }
    }
}

struct BloomPlantIdentity: View {
    let plant: Plant
    var body: some View {
        HStack(spacing: 12) {
            PlantPortrait(plant: plant, contentMode: .fit).frame(width: 48, height: 58).clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text(plant.name).font(BloomType.section)
                Text(plant.location.isEmpty ? "Your plant" : plant.location).font(BloomType.body).foregroundStyle(.secondary)
            }
        }.accessibilityElement(children: .combine)
    }
}


/// Transient feedback stays with the user's plant; it is never part of saved garden data.
struct CareFlowFeedback: Identifiable {
    let id = UUID()
    let plantID: UUID
    var title: String
    var detail: String
    var planID: UUID? = nil
    var receipt: PlanTaskReceipt? = nil
    var isSuccess = true
}

struct CareFeedbackBanner: View {
    @Environment(BloomStore.self) private var store
    var plantID: UUID? = nil
    @State private var guidance: CareGuidanceDestination?
    @State private var resolving = false
    @State private var scheduling = false
    var body: some View {
        if let feedback = store.careFeedback, plantID == nil || feedback.plantID == plantID {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        if plantID == nil, let plant = store.plant(feedback.plantID) { Text(plant.name).font(BloomType.supporting).foregroundStyle(BloomTheme.secondary) }
                        Group {
                            if feedback.isSuccess { Label(feedback.title, systemImage: "checkmark.circle.fill") }
                            else { Text(feedback.title) }
                        }.font(BloomType.section).accessibilityIdentifier("care-feedback-title")
                        Text(feedback.detail).font(BloomType.body).foregroundStyle(BloomTheme.secondary)
                            .accessibilityIdentifier("care-feedback-detail")
                    }
                    Spacer(minLength: 8)
                    Button { store.careFeedback = nil } label: { BloomSymbol(name: "xmark").frame(width: 44, height: 44) }
                        .accessibilityLabel("Dismiss confirmation").accessibilityIdentifier("dismiss-care-feedback")
                }
                if let receipt = feedback.receipt {
                    HStack(spacing: 20) {
                        if store.canUndoPlanTask(receipt) {
                            Button("Undo") {
                                if store.undoPlanTask(receipt) {
                                    store.careFeedback = CareFlowFeedback(plantID: feedback.plantID,
                                        title: receipt.task.step == .review ? "Check-in reopened" : "Action reopened",
                                        detail: "Your task is ready to complete again.", isSuccess: false)
                                }
                            }
                                .accessibilityIdentifier("undo-plan-task")
                        }
                        if let planID = feedback.planID, let record = store.record(receipt.recordID), record.kind == .followUp, store.planIsOpen(planID) {
                            if PlanOutcome.fromStored(record.outcome) == PlanOutcome.none {
                                Button("Mark issue as resolved") { resolving = true }.accessibilityIdentifier("resolve-after-check")
                            } else if let plan = store.carePlan(planID), plan.status == .needsReview {
                                Button("Review next step") { guidance = CareGuidanceDestination(id: plan.observationID) }.accessibilityIdentifier("reassess-after-check")
                            } else {
                                Button("Check again later") { scheduling = true }.accessibilityIdentifier("schedule-after-check")
                            }
                        }
                    }.font(BloomType.section).buttonStyle(.bordered).controlSize(.small)
                }
            }.foregroundStyle(feedback.isSuccess ? BloomTheme.teal : BloomTheme.ink).padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: BloomTheme.cardRadius))
                .overlay(RoundedRectangle(cornerRadius: BloomTheme.cardRadius).strokeBorder(BloomTheme.border))
                .padding(.horizontal, 16).padding(.vertical, 8)
                .accessibilityElement(children: .contain)
                .sheet(isPresented: $scheduling) {
                    if let id = feedback.planID { PlanReviewScheduleView(planID: id) }
                }
                .sheet(item: $guidance) { destination in
                    CareGuidanceFlow(observationID: destination.id, replacing: feedback.planID)
                }
                .confirmationDialog("Mark this issue as resolved?", isPresented: $resolving, titleVisibility: .visible) {
                    Button("Mark resolved") {
                        if let id = feedback.planID, store.closePlan(id, resolved: true) {
                            store.careFeedback = CareFlowFeedback(plantID: feedback.plantID, title: "Issue resolved", detail: "Your observations and care steps stay in Activity.")
                        }
                    }
                } message: { Text("This closes the issue and cancels its pending tasks. Your saved activity stays available.") }
        }
    }
}

// Display copy is separate from the persisted status raw values.
extension PlanTaskStatus {
    var displayTitle: String { self == .completed ? "Completed" : rawValue }
}
