import SwiftUI

struct CareGuidanceFlow: View {
    @Environment(BloomStore.self) private var store
    let observationID: UUID
    var replacing: UUID? = nil
    var justSaved = false
    var returnLabel = "Back to plant"
    var finish: (() -> Void)? = nil
    @State private var visualEntry: Bool?
    var body: some View {
        Group {
            if store.record(observationID) == nil { ContentUnavailableView("Observation unavailable", systemImage: "leaf") }
            else if let visualEntry {
                if visualEntry { LeafCareGuidanceFlow(observationID: observationID, replacing: replacing, justSaved: justSaved, returnLabel: returnLabel, finish: finish) }
                else { PestCareGuidanceFlow(observationID: observationID, replacing: replacing, justSaved: justSaved, finish: finish) }
            } else { ProgressView() }
        }.onAppear {
            guard visualEntry == nil, let observation = store.record(observationID) else { return }
            // Keep the presentation stable while optional checks update the saved observation.
            visualEntry = ObservationGuidanceRoute.usesVisualEntry(observation, replacing: replacing.flatMap(store.carePlan))
        }
    }
}

/// Advice is available immediately. Additional observations refine it without blocking a task.
struct LeafCareGuidanceFlow: View {
    @Environment(BloomStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let observationID: UUID
    var replacing: UUID? = nil
    var justSaved = false
    var returnLabel = "Back to plant"
    var finish: (() -> Void)? = nil
    @State private var answers = LeafAssessment()
    @State private var initialized = false
    @State private var message: String?
    @State private var checkingPests = false
    @State private var refining = false
    private var observation: CareRecord? { store.record(observationID) }
    private var plant: Plant? { observation.flatMap { store.plant($0.plantID) } }
    private var isPest: Bool {
        observation?.area == .pests || answers.warning == .pests || (observation?.assessment != nil && observation?.leafAssessment == nil)
    }
    private var kind: CarePlanKind {
        if isPest { return observation?.assessment?.recommendation ?? .inspection }
        guard let observation, let plant else { return .leafInspection }
        return answers.recommendation(for: observation, plant: plant)
    }
    var body: some View {
        NavigationStack {
            Group {
                if let observation, let plant {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            if justSaved { Label("Change saved", systemImage: "checkmark.circle.fill").font(BloomType.section).foregroundStyle(BloomTheme.teal).accessibilityIdentifier("observation-saved-notice") }
                            HStack(alignment: .center, spacing: 16) {
                                PlantPortrait(plant: plant, contentMode: .fit).frame(width: 64, height: 76)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(plant.name).font(BloomType.body).foregroundStyle(.secondary)
                                    Text(observation.observation).bloomHeading(BloomTheme.heading)
                                }
                            }.accessibilityElement(children: .combine)
                            if !kind.needsSpecialist { possibilities(observation) }
                            firstAction
                            if isPest || answers.warning == .pests {
                                Button { checkingPests = true } label: {
                                    Text("Take a closer look at the pests")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }.buttonStyle(.bordered).controlSize(.large).accessibilityIdentifier("leaf-check-pests")
                            }
                            if !isPest {
                                DisclosureGroup(isExpanded: $refining) { quickChecks.padding(.top, 12) } label: {
                                    Text("I've checked my plant").font(BloomType.section)
                                }
                            }
                            DisclosureGroup("Why this might help") {
                                VStack(alignment: .leading, spacing: 14) {
                                    Text("Similar changes can have different causes. Start with a close look before choosing a treatment.").font(BloomType.body).foregroundStyle(.secondary)
                                    Text("Possible causes, not a confirmed diagnosis.").font(BloomType.supporting)
                                    ForEach((isPest ? CareGuidanceSources.sources : LeafCareSources.sources), id: \.1) { source in
                                        Link(source.0, destination: URL(string: source.1)!).font(BloomType.body)
                                    }
                                }.padding(.top, 12)
                            }.font(BloomType.body)
                            if !kind.needsSpecialist && !isPest {
                                Menu {
                                    Button("Soft or blackened stems") { update { $0.warning = .soft } }
                                    Button("Rapid decline or heavy leaf loss") { update { $0.warning = .rapid } }
                                    Button("Visible insects or webbing") { update { $0.warning = .pests }; checkingPests = true }
                                } label: {
                                    Text("Getting worse or seeing pests?")
                                        .font(BloomType.body).foregroundStyle(BloomTone.yellow.ink)
                                }.accessibilityIdentifier("leaf-help-sooner")
                            }
                            if !observation.note.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Your note").font(BloomType.supporting).foregroundStyle(BloomTheme.secondary)
                                    Text(observation.note).font(BloomType.body)
                                }.bloomCard(padding: 16)
                            }
                            if let message { Text(message).font(BloomType.body).foregroundStyle(.red).accessibilityIdentifier("leaf-save-error") }
                        }.padding(20).frame(maxWidth: 620).frame(maxWidth: .infinity)
                    }.background(BloomTheme.canvas).navigationTitle("What could help").navigationBarTitleDisplayMode(.inline)
                        .bloomNativeFooter {
                            if replacing == nil, let existing = store.plan(for: observationID), store.planIsOpen(existing.id) {
                                NavigationLink { CarePlanDetailView(planID: existing.id) } label: {
                                    Text("View care plan").frame(maxWidth: .infinity)
                                }.buttonStyle(BloomPrimaryButtonStyle()).accessibilityIdentifier("leaf-view-care-plan")
                            } else {
                            BloomPrimaryAction(title: replacing == nil ? "Add to care plan" : "Update care plan") {
                                let id: UUID?
                                if isPest, let assessment = observation.assessment {
                                    id = store.startCarePlan(observationID: observationID, answers: assessment, reviewDays: nil, replacing: replacing)
                                } else if isPest, observation.area == .pests {
                                    id = store.startPestInspectionPlan(observationID: observationID, reviewDays: nil, replacing: replacing)
                                } else if isPest {
                                    id = store.startCarePlan(observationID: observationID, answers: PestAssessment(), reviewDays: nil, replacing: replacing)
                                } else {
                                    id = store.startLeafCarePlan(observationID: observationID, answers: answers, reviewDays: nil, replacing: replacing)
                                }
                                if let id {
                                    store.announceCarePlan(id)
                                    BloomFeedback.success(); finishFlow()
                                } else { message = "Your task couldn't be saved. Please try again; your observation is still here." }
                            }.accessibilityIdentifier("leaf-start-care-plan")
                            }
                        }
                } else { ContentUnavailableView("Observation unavailable", systemImage: "leaf") }
            }
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button(justSaved ? returnLabel : "Close", systemImage: justSaved ? "chevron.backward" : "xmark", action: finishFlow).labelStyle(.iconOnly).accessibilityIdentifier("close-guidance") } }
        }
        .onAppear {
            guard !initialized else { return }; initialized = true
            answers = observation?.leafAssessment ?? LeafAssessment()
            // Reuse facts the user has already provided, without turning unknowns into answers.
            if answers.placement == nil, let placement = plant?.placement { answers.placement = placement == .indoor ? .indoor : .outdoor }
            if answers.environment == nil {
                if observation?.lightChanged == "Yes" { answers.environment = .yes }
                if observation?.lightChanged == "No" { answers.environment = .no }
            }
            if answers.drainage == nil {
                if plant?.drainage == "Yes" { answers.drainage = .yes }
                if plant?.drainage == "No" { answers.drainage = .no }
            }
        }
        .fullScreenCover(isPresented: $checkingPests) { PestCareGuidanceFlow(observationID: observationID, replacing: replacing) }
        .onChange(of: checkingPests) { _, open in
            if !open, let active = store.plan(for: observationID), store.planIsOpen(active.id), active.id != replacing {
                finishFlow()
            }
        }
    }
    private func finishFlow() { if let finish { finish() } else { dismiss() } }
    private func possibilities(_ observation: CareRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Possible causes").bloomHeading()
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 10) { causeTiles(observation) }
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .top), count: 3), alignment: .leading, spacing: 10) { causeTiles(observation) }
            }
            Text("These can look alike. You don't need to choose a cause.").font(BloomType.supporting).foregroundStyle(.secondary)
        }.accessibilityIdentifier("leaf-possible-causes")
    }
    @ViewBuilder private func causeTiles(_ observation: CareRecord) -> some View {
        let spots = observation.observation == "Spots or patches"
        if isPest {
            causeTile("Mealybugs", subtitle: "Cottony clusters", symbol: "ant", tone: .teal)
            causeTile("Mites", subtitle: "Fine webbing", symbol: "circle.dotted", tone: .yellow)
            causeTile("Other pests", subtitle: "Check closely", symbol: "magnifyingglass", tone: .blue)
        } else {
        causeTile(spots ? "Leaf moisture" : "Water balance", subtitle: spots ? "Wet leaves" : "Too wet or dry", symbol: "drop.fill", tone: .blue)
        causeTile("Conditions", subtitle: "Light or temperature", symbol: "sun.max.fill", tone: .yellow)
        causeTile(observation.observation == "Dropping leaves" ? "Older leaves" : "Pests or damage", subtitle: observation.observation == "Dropping leaves" ? "Natural shedding" : "Look underneath", symbol: "leaf.fill", tone: .teal)
        }
    }
    private func causeTile(_ title: String, subtitle: String, symbol: String, tone: BloomTone) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            BloomSymbol(name: symbol).foregroundStyle(tone.ink).accessibilityHidden(true)
            Text(title).font(BloomType.section).foregroundStyle(BloomTheme.ink)
            Text(subtitle).font(BloomType.supporting).foregroundStyle(BloomTheme.secondary)
        }.frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
            .padding(12).background(tone.surface, in: RoundedRectangle(cornerRadius: 16))
            .accessibilityElement(children: .combine)
    }
    private var careSteps: [CarePlanStep] { kind.actionSteps(for: observation?.area) }
    private var firstAction: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(kind.needsSpecialist ? "Get help sooner" : careSteps.count > 1 ? "Your care steps" : "Your first step", systemImage: kind.needsSpecialist ? "exclamationmark.bubble.fill" : "hand.point.up.left.fill")
                .font(BloomType.section).foregroundStyle(kind.needsSpecialist ? BloomTone.yellow.ink : BloomTheme.teal)
            Text(kind.title).bloomHeading().accessibilityIdentifier("leaf-recommendation-title")
            Text(kind.explanation(for: observation?.area)).font(BloomType.supporting).foregroundStyle(BloomTheme.secondary)
            ForEach(careSteps, id: \.self) { step in BloomCareStepSummary(step: step) }
            DisclosureGroup("How to do this") {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(careSteps, id: \.self) { step in
                        ForEach(step.instructions, id: \.self) { Text($0).font(BloomType.body).foregroundStyle(.secondary) }
                    }
                }.padding(.top, 8)
            }.font(BloomType.body)
        }.padding(18).frame(maxWidth: .infinity, alignment: .leading)
            .background(BloomTheme.surface, in: RoundedRectangle(cornerRadius: BloomTheme.cardRadius))
            .overlay(RoundedRectangle(cornerRadius: BloomTheme.cardRadius).strokeBorder(kind.needsSpecialist ? BloomTone.yellow.accent : BloomTheme.border, lineWidth: 1))
            .animation(reduceMotion ? nil : BloomTheme.spring, value: kind)
    }
    private var quickChecks: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Optional · Share what you noticed to refine this step.").font(BloomType.supporting).foregroundStyle(.secondary)
            Text("How does the mix feel?").font(BloomType.section)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130))], spacing: 10) {
                soilOption(.dry, title: "Dry", detail: "Below the surface", symbol: "sun.max")
                soilOption(.moist, title: "Moist", detail: "Not soggy", symbol: "drop.halffull")
                soilOption(.soggy, title: "Very wet", detail: "Soggy or pooled water", symbol: "water.waves")
                soilOption(.unsure, title: "Not sure", detail: "Keep the first step", symbol: "questionmark")
            }
            if answers.soil == .dry {
                Text("Can water drain out?").font(BloomType.section)
                Picker("Can water drain out?", selection: Binding(get: { answers.drainage }, set: { v in update { $0.drainage = v } })) {
                    Text("Not checked").tag(LeafDrainage?.none)
                    ForEach(LeafDrainage.allCases) { Text($0.rawValue).tag(Optional($0)) }
                }.pickerStyle(.menu).accessibilityIdentifier("leaf-assessment-drainage")
            }
            Text("Other signs").font(BloomType.section)
            Picker("Other signs", selection: Binding(get: { answers.warning }, set: { v in update { $0.warning = v } })) {
                Text("Not checked").tag(LeafWarning?.none)
                ForEach(LeafWarning.allCases) { Text($0.rawValue).tag(Optional($0)) }
            }.pickerStyle(.menu).accessibilityIdentifier("leaf-assessment-warning")
            if answers.soil == .moist || answers.soil == .unsure || answers.soil == nil {
                Text("Recently moved or changed light?").font(BloomType.section)
                Picker("Recently moved or changed light?", selection: Binding(get: { answers.environment }, set: { v in update { $0.environment = v } })) {
                    Text("Not checked").tag(LeafEnvironmentChange?.none)
                    ForEach(LeafEnvironmentChange.allCases) { Text($0.rawValue).tag(Optional($0)) }
                }.pickerStyle(.menu).accessibilityIdentifier("leaf-assessment-environment")
            }
            if answers.placement == nil || answers.placement == .unsure {
                Text("Growing space unknown. We'll keep this to a closer look; you can add the space in plant details later.").font(BloomType.supporting).foregroundStyle(.secondary)
            }
            Button("Clear my checks") {
                update { $0 = LeafAssessment(placement: plant?.placement.map { $0 == .indoor ? .indoor : .outdoor }) }
            }.font(BloomType.body).accessibilityIdentifier("leaf-reset-checks")
        }.padding(16).background(BloomTheme.surface, in: RoundedRectangle(cornerRadius: 16))
    }
    private func soilOption(_ soil: LeafSoil, title: String, detail: String, symbol: String) -> some View {
        Button { update { $0.soil = soil } } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack { BloomSymbol(name: symbol); Spacer(); if answers.soil == soil { BloomSymbol(name: "checkmark.circle.fill") } }
                    .foregroundStyle(BloomTheme.teal).accessibilityHidden(true)
                Text(title).font(BloomType.section)
                Text(detail).font(BloomType.supporting).foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity, minHeight: 76, alignment: .leading).padding(12)
                .background(answers.soil == soil ? BloomTheme.selected : BloomTheme.canvas, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(answers.soil == soil ? BloomTheme.teal : BloomTheme.border))
                .contentShape(RoundedRectangle(cornerRadius: 12))
        }.buttonStyle(.plain).accessibilityIdentifier("leaf-soil-\(soil)")
            .accessibilityAddTraits(answers.soil == soil ? .isSelected : [])
    }
    private func update(_ change: (inout LeafAssessment) -> Void) {
        var next = answers; change(&next)
        if store.saveLeafAssessment(next, observationID: observationID) { answers = next; message = nil; BloomFeedback.selection() }
        else { message = "Your checks couldn't be saved. Please try again." }
    }
}

extension CarePlanKind {
    var quickTitle: String {
        switch self {
        case .leafDry: "Check before watering"
        case .leafWet: "Let excess water drain"
        case .leafEnvironment: "Keep conditions steady"
        case .leafExpert: "Ask for a closer assessment"
        default: "Take a closer look"
        }
    }
}

/// Short illustrated instructions remain paired with optional full guidance.
struct LeafVisualSteps: View {
    let step: CarePlanStep
    private var items: [(String, String, String)] {
        switch step {
        case .checkSoilMoisture: [("hand.point.down", "Feel below the surface", "Compare with this plant's moisture needs before watering.")]
        case .checkGrowingConditions: [("sun.max", "Check its growing spot", "Note light, temperature and any recent moves.")]
        case .checkLeafChanges: [("leaf", "Look for new changes", "Inspect both sides of leaves; compare older and newer growth.")]
        case .separate: [("arrow.left.and.right", "Give it space", "Keep suitable light, away from other plants."), ("leaf", "Check nearby plants", "Look under leaves and around stems."), ("sparkles", "Keep tools clean", "Clean tools before using them elsewhere.")]
        case .removeBugs: [("magnifyingglass", "Check the visible insects", "Look for individual cottony insects in good light."), ("hand.point.up.left", "Remove gently", "Use tweezers; support the leaf and avoid scraping."), ("exclamationmark.circle", "Stop if it is difficult", "Get help for fragile areas or extensive damage.")]
        case .inspect: [("leaf", "Look under leaves", "Check stems and leaf joints too."), ("magnifyingglass", "Look for visible signs", "Note clusters, insects or webbing."), ("photo", "Keep a comparison", "Use a close-up and your saved observation.")]
        case .waterDryRoots: [("hand.point.down", "Check below the surface", "Use this plant's moisture needs."), ("drop", "Water only if needed", "Let excess water drain; empty the saucer.")]
        case .drainExcessWater: [("drop.triangle", "Empty standing water", "Let the pot drain freely."), ("hand.point.down", "Check before watering again", "Drooping alone doesn't mean it needs water.")]
        case .steadyConditions: [("sun.max", "Find a suitable spot", "Follow this plant's light and temperature needs."), ("wind", "Keep it steady", "Avoid draughts, heaters and repeated moves.")]
        case .askExpert: [("person.crop.circle.badge.questionmark", "Ask a plant-care specialist", "Bring your saved observation and photos.")]
        default: [("hand.point.down", "Feel the mix", "Check below the surface before watering."), ("leaf", "Look underneath", "Check leaves and stems for pests or damage."), ("photo", "Keep a comparison", "Use your saved photo or note as a starting point.")]
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(items.indices, id: \.self) { i in
                HStack(alignment: .top, spacing: 12) {
                    BloomIconTile(symbol: items[i].0, tone: tone)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(items[i].1).font(BloomType.section)
                        Text(items[i].2).font(BloomType.supporting).foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }.accessibilityElement(children: .combine)
            }
        }
    }
    private var tone: BloomTone {
        switch step {
        case .checkSoilMoisture, .waterDryRoots, .drainExcessWater: .blue
        case .checkGrowingConditions, .steadyConditions: .yellow
        default: .teal
        }
    }
}
