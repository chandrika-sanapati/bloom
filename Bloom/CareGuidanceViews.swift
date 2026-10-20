import SwiftUI

struct CareGuidanceEntry: View {
    @Environment(BloomStore.self) private var store
    let observationID: UUID
    var open: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let plan = store.plan(for: observationID) {
                NavigationLink { CarePlanDetailView(planID: plan.id) } label: {
                    Label("View care plan", systemImage: "list.bullet.clipboard")
                }.accessibilityIdentifier("view-care-plan")
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Understand what to do next").font(.headline)
                    Text("A few checks can help you choose a suitable action. Your observation is already saved.").font(.subheadline).foregroundStyle(.secondary)
                    Button("Find next steps", systemImage: "leaf", action: open)
                        .buttonStyle(.borderedProminent).accessibilityIdentifier("find-next-steps")
                }.padding(.vertical, 6)
            }
        }
    }
}

private enum GuidancePage: Hashable { case recommendation }
struct CareGuidanceFlow: View {
    @Environment(BloomStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let observationID: UUID
    var replacing: UUID? = nil
    @State private var answers = PestAssessment()
    @State private var path: [GuidancePage] = []
    @State private var startedPlanID: UUID?
    @State private var followUp = true
    @State private var days = 7
    @State private var initialized = false
    @State private var message: String?
    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if let startedPlanID { started(startedPlanID) }
                else if let observation = store.record(observationID), let plant = store.plant(observation.plantID) {
                    Form {
                        Section {
                            BloomPlantIdentity(plant: plant)
                            Text(observation.observation).font(.headline)
                            Text("Let's look for a pattern before choosing an action. Photos are kept as evidence; Bloom isn't identifying pests from them.").font(.subheadline).foregroundStyle(.secondary)
                        }
                        Section {
                            Picker("Visible signs", selection: $answers.signs) {
                                Text("Choose what you see").tag(PestSigns?.none)
                                ForEach(PestSigns.allCases) { Text($0.rawValue).tag(Optional($0)).accessibilityIdentifier("assessment-sign-\($0.rawValue)") }
                            }.pickerStyle(.inline)
                        } header: { Text("What can you see?") }
                        Section("A little more detail") {
                            Picker("Where?", selection: $answers.location) {
                                Text("Choose a place").tag(PestLocation?.none)
                                ForEach(PestLocation.allCases) { Text($0.rawValue).tag(Optional($0)) }
                            }.accessibilityIdentifier("assessment-location")
                            Picker("How widespread?", selection: $answers.extent) {
                                Text("Choose an extent").tag(PestExtent?.none)
                                ForEach(PestExtent.allCases) { Text($0.rawValue).tag(Optional($0)) }
                            }.accessibilityIdentifier("assessment-extent")
                            Picker("Plant placement", selection: $answers.placement) {
                                Text("Choose placement").tag(AssessmentPlacement?.none)
                                ForEach(AssessmentPlacement.allCases) { Text($0.rawValue).tag(Optional($0)) }
                            }.accessibilityIdentifier("assessment-placement")
                        }
                        Section { Text("Not sure is a useful answer. Unclear signs lead to an inspection, rather than an assumed treatment.").font(.footnote).foregroundStyle(.secondary) }
                        if let message { Section { Text(message).foregroundStyle(.red) } }
                    }.bloomNativeForm().navigationTitle("Understand the change").navigationBarTitleDisplayMode(.inline)
                        .bloomNativeFooter {
                            BloomPrimaryAction(title: "See next steps") {
                                if store.saveAssessment(answers, observationID: observationID) {
                                    days = answers.recommendation.defaultReviewDays
                                    followUp = answers.recommendation != .expert
                                    message = nil; path.append(.recommendation)
                                }
                            }.disabled(!answers.complete).accessibilityIdentifier("assessment-continue")
                        }
                } else { ContentUnavailableView("Observation unavailable", systemImage: "leaf") }
            }
            .toolbar { if startedPlanID == nil { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } } }
            .navigationDestination(for: GuidancePage.self) { _ in
                if let startedPlanID { started(startedPlanID) }
                else { recommendation }
            }
        }.onChange(of: answers) { _, next in
            if initialized { _ = store.saveAssessment(next, observationID: observationID) }
        }.onAppear {
            guard !initialized else { return }; initialized = true
            if let saved = store.record(observationID)?.assessment { answers = saved }
            if answers.placement == nil, let plantID = store.record(observationID)?.plantID, let placement = store.plant(plantID)?.placement {
                answers.placement = placement == .indoor ? .indoor : .outdoor
            }
        }
    }
    private var recommendation: some View {
        List {
            Section {
                StatusTag(text: answers.recommendation == .mealybugs ? "Possible match" : "More evidence needed", tone: answers.recommendation == .mealybugs ? .teal : .yellow)
                Text(answers.recommendation.title).font(.title2.weight(.semibold))
                Text(answers.recommendation.explanation).foregroundStyle(.secondary)
            }
            Section("Your starting steps") {
                ForEach(Array(answers.recommendation.actionSteps.enumerated()), id: \.offset) { index, step in
                    DisclosureGroup {
                        Text(step.materials).font(.subheadline.weight(.medium))
                        ForEach(step.instructions, id: \.self) { Text($0).font(.subheadline) }
                    } label: { Label(step.title, systemImage: "\(index + 1).circle") }
                }
            }
            Section("What to look for") { Text(answers.recommendation.improvement) }
            Section {
                Toggle("Check progress after the actions", isOn: $followUp).accessibilityIdentifier("plan-follow-up-toggle")
                if followUp {
                    Picker("Suggested check-in", selection: $days) {
                        ForEach([1, 3, 7, 14], id: \.self) { Text("After \($0) \($0 == 1 ? "day" : "days")").tag($0) }
                    }
                }
            } header: { Text("Your follow-up · Optional") } footer: {
                Text("This is an editable inspection interval, not a promised recovery time. The clock starts when you record the actions as done. Starting the plan won't enable notifications.")
            }
            CareGuidanceSourceSection()
            if let message { Section { Text(message).foregroundStyle(.red) } }
        }.listStyle(.insetGrouped).bloomNativeForm().navigationTitle("Your next steps").navigationBarTitleDisplayMode(.inline)
            .bloomNativeFooter {
                BloomPrimaryAction(title: replacing == nil ? "Start this care plan" : "Start revised plan", symbol: "plus") {
                    if let id = store.startCarePlan(observationID: observationID, answers: answers, reviewDays: followUp ? days : nil, replacing: replacing) {
                        startedPlanID = id; path = []; BloomFeedback.success()
                    } else { message = "The plan couldn't be started. Your observation is still saved." }
                }.accessibilityIdentifier("start-care-plan")
            }
    }
    private func started(_ id: UUID) -> some View {
        CarePlanDetailView(planID: id).navigationBarBackButtonHidden()
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() }.accessibilityIdentifier("finish-plan-setup") } }
    }
}

struct CareGuidanceSourceSection: View {
    var body: some View {
        Section {
            ForEach(CareGuidanceSources.sources, id: \.1) { source in Link(source.0, destination: URL(string: source.1)!) }
        } header: { Text("Why these steps?") } footer: {
            Text("Based on university extension guidance. Sources checked 19 October 2026. This focused plan uses inspection and physical removal; it doesn't prescribe a spray or guarantee recovery.")
        }
    }
}
