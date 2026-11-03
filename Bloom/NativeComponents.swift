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

/// One add control across Home and the full collection.
struct BloomAddPlantButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            BloomSymbol(name: "plus").foregroundStyle(BloomTheme.teal)
                .frame(width: 44, height: 44).background(.white, in: Circle())
                .overlay(Circle().strokeBorder(BloomTheme.border, lineWidth: 1))
        }.buttonStyle(BloomPressStyle()).accessibilityLabel("Add plant")
            .accessibilityHint("Search for a plant to add to My plants")
    }
}

struct BloomActionRow: View {
    let title: String
    var body: some View {
        HStack(spacing: 12) {
            Text(title).font(BloomType.section).foregroundStyle(BloomTheme.ink)
            Spacer(minLength: 8)
            BloomSymbol(name: "chevron.right", compact: true).foregroundStyle(BloomTheme.teal)
        }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
    }
}

/// Read-only scheduling context, visually separated from the action that opens its editor.
struct BloomDatedStatusRow: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    let title: String
    let value: String
    var accessibilityValue: String? = nil
    var body: some View {
        Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(BloomType.body.weight(.semibold)).foregroundStyle(BloomTheme.secondary)
                    Text(value).font(BloomType.body).foregroundStyle(BloomTheme.ink)
                }.frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(title).font(BloomType.body.weight(.semibold)).foregroundStyle(BloomTheme.secondary)
                    Spacer(minLength: 8)
                    Text(value).font(BloomType.body).foregroundStyle(BloomTheme.ink)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .padding(12).frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .background(BloomTheme.canvas, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(accessibilityValue ?? value)")
    }
}

extension View {
    func bloomNativeForm() -> some View {
        scrollContentBackground(.hidden).background(BloomTheme.canvas)
            .headerProminence(.increased).textCase(nil)
            .listSectionSpacing(16).contentMargins(.top, 12, for: .scrollContent)
            .navigationLinkIndicatorVisibility(.hidden)
    }
    func bloomNativeFooter<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        safeAreaInset(edge: .bottom) { content().padding(.horizontal, 20).padding(.vertical, 12).background(.bar) }
    }
}

/// Shared page and selection treatment mirrors the interactive demo while retaining native controls.
struct BloomContentPage<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20, content: content)
                .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 24)
                .frame(maxWidth: 620).frame(maxWidth: .infinity)
        }.background(BloomTheme.canvas).scrollDismissesKeyboard(.interactively)
    }
}

struct BloomChoiceList<Value: Hashable>: View {
    let values: [Value]
    @Binding var selection: Value?
    var title: (Value) -> String
    var identifier: (Value) -> String = { _ in "" }
    var body: some View {
        VStack(spacing: 0) {
            ForEach(values, id: \.self) { value in
                let selected = selection == value
                Button { selection = value; BloomFeedback.selection() } label: {
                    HStack(spacing: 12) {
                        Text(title(value)).font(selected ? BloomType.section : BloomType.body)
                            .foregroundStyle(BloomTheme.ink).fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 8)
                        BloomSymbol(name: selected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selected ? BloomTheme.teal : BloomTheme.secondary)
                    }.padding(.horizontal, 16).padding(.vertical, 14)
                        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                        .background(selected ? BloomTheme.selected : BloomTheme.surface)
                        .contentShape(Rectangle())
                }.buttonStyle(.plain)
                    .accessibilityLabel(title(value)).accessibilityValue(selected ? "Selected" : "Not selected")
                    .accessibilityAddTraits(selected ? .isSelected : [])
                    .accessibilityIdentifier(identifier(value))
                if value != values.last { Divider().padding(.leading, 16) }
            }
        }.clipShape(RoundedRectangle(cornerRadius: BloomTheme.cardRadius))
    }
}

struct BloomSelectionHint: View {
    var body: some View {
        Text("Choose an option above to continue.").font(BloomType.supporting)
            .foregroundStyle(BloomTheme.secondary).frame(maxWidth: .infinity)
            .accessibilityIdentifier("selection-hint")
    }
}

extension View {
    func bloomInput() -> some View {
        padding(12).background(BloomTheme.surface, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(BloomTheme.border))
    }
}

struct BloomPlantIdentity: View {
    let plant: Plant
    var body: some View {
        HStack(spacing: 12) {
            PlantPortrait(plant: plant, contentMode: .fit).frame(width: 48, height: 58).clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text(plant.displayName).font(BloomType.section)
                Text(plant.location.isEmpty ? "Your plant" : plant.location).font(BloomType.body).foregroundStyle(.secondary)
            }
        }.accessibilityElement(children: .combine)
    }
}


/// Recent recorded soil and watering care belongs with plant identity, independently of reminders.
struct PlantStatusSummary: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    let check: CareRecord?
    let lastWatered: Date?
    @ScaledMetric(relativeTo: .body) private var iconSize = 36
    private func dateLabel(_ date: Date?) -> String {
        guard let date else { return "Not recorded" }
        let style = Date.FormatStyle.dateTime.day().month(.abbreviated)
        return date.formatted(Calendar.current.isDate(date, equalTo: .now, toGranularity: .year) ? style : style.year())
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent care").font(BloomType.section).foregroundStyle(BloomTheme.ink)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 10) {
                statusRow("Last soil check", date: check?.date, symbol: "checkmark.circle", tone: .teal)
                Rectangle().fill(BloomTheme.border).frame(height: 1).padding(.leading, iconSize + 10)
                statusRow("Last watered", date: lastWatered, symbol: "drop", tone: .blue)
            }
        }.padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .background(BloomTheme.canvas, in: RoundedRectangle(cornerRadius: 12))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Recent care. Last soil check: \(check?.date.formatted(date: .complete, time: .shortened) ?? "Not recorded"). Last watered: \(lastWatered?.formatted(date: .complete, time: .omitted) ?? "Not recorded").")
    }
    private func dateValue(_ date: Date?) -> some View {
        Text(dateLabel(date)).font(BloomType.supporting).foregroundStyle(BloomTheme.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
    private func statusRow(_ label: String, date: Date?, symbol: String, tone: BloomTone) -> some View {
        HStack(spacing: 10) {
            BloomSymbol(name: symbol).foregroundStyle(tone.ink)
                .frame(width: iconSize, height: iconSize)
                .background(tone.surface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 4) {
                    Text(label).font(BloomType.section).foregroundStyle(BloomTheme.ink)
                    dateValue(date)
                }.frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(label).font(BloomType.section).foregroundStyle(BloomTheme.ink)
                Spacer(minLength: 8)
                dateValue(date).multilineTextAlignment(.trailing)
            }
        }.frame(maxWidth: .infinity, minHeight: max(44, iconSize), alignment: .leading)
    }
}

/// Transient feedback stays with the user's plant; it is never part of saved garden data.
struct CareFlowFeedback: Identifiable {
    static let dismissalDuration: TimeInterval = 2.5
    let id = UUID()
    let plantID: UUID
    var title: String
    var detail: String
    var planID: UUID? = nil
    var receipt: PlanTaskReceipt? = nil
    var careReceipt: CareSaveReceipt? = nil
    var isSuccess = true
    var autoDismiss = true
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
                        if plantID == nil, let plant = store.plant(feedback.plantID) { Text(plant.displayName).font(BloomType.supporting).foregroundStyle(BloomTheme.secondary) }
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
                } else if let receipt = feedback.careReceipt {
                    Button("Undo") {
                        Task {
                            if await store.undoCare(receipt), store.careFeedback?.id == feedback.id {
                                withAnimation { store.careFeedback = nil }
                            }
                        }
                    }
                    .font(BloomType.section).buttonStyle(.bordered).controlSize(.small)
                    .accessibilityIdentifier("undo-record")
                }
            }.foregroundStyle(feedback.isSuccess ? BloomTheme.teal : BloomTheme.ink).padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: BloomTheme.cardRadius))
                .overlay(RoundedRectangle(cornerRadius: BloomTheme.cardRadius).strokeBorder(BloomTheme.border))
                .padding(.horizontal, 16).padding(.vertical, 8)
                .accessibilityElement(children: .contain)
                .task(id: feedback.id) {
                    // Keep receipt banners visible while Undo or another recovery action is available.
                    guard feedback.autoDismiss, feedback.receipt == nil else { return }
                    try? await Task.sleep(nanoseconds: UInt64(CareFlowFeedback.dismissalDuration * 1_000_000_000))
                    guard !Task.isCancelled, store.careFeedback?.id == feedback.id else { return }
                    withAnimation { store.careFeedback = nil }
                }
                .sheet(isPresented: $scheduling) {
                    if let id = feedback.planID { PlanReviewScheduleView(planID: id) }
                }
                .fullScreenCover(item: $guidance) { destination in
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

struct BloomCareStepSummary: View {
    let step: CarePlanStep
    private var tone: BloomTone {
        switch step { case .checkSoilMoisture, .waterDryRoots, .drainExcessWater: .blue; case .checkGrowingConditions, .steadyConditions: .yellow; default: .teal }
    }
    private var symbol: String {
        switch step { case .checkSoilMoisture, .waterDryRoots, .drainExcessWater: "drop"; case .checkGrowingConditions, .steadyConditions: "sun.max"; case .checkLeafChanges: "leaf"; case .separate: "arrow.left.and.right"; case .removeBugs, .inspect: "magnifyingglass"; case .askExpert: "person.crop.circle.badge.questionmark"; default: "eye" }
    }
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            BloomIconTile(symbol: symbol, tone: tone)
            VStack(alignment: .leading, spacing: 4) {
                Text(step.title).font(BloomType.section)
            }.frame(maxWidth: .infinity, alignment: .leading)
        }.accessibilityElement(children: .combine)
    }
}
