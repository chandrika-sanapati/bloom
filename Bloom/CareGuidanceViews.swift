import SwiftUI

struct CareGuidanceDestination: Identifiable { let id: UUID }

struct CareGuidanceEntry: View {
    @Environment(BloomStore.self) private var store
    let observationID: UUID
    var open: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let plan = store.plan(for: observationID) {
                NavigationLink { CarePlanDetailView(planID: plan.id) } label: {
                    Text("View care plan").frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
                }.accessibilityIdentifier("view-care-plan")
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Understand what to do next").font(BloomType.section)
                    Button("Find next steps", action: open)
                        .buttonStyle(BloomPrimaryButtonStyle()).accessibilityIdentifier("find-next-steps")
                }.padding(.vertical, 6)
            }
        }
    }
}

private enum GuidancePage: Hashable { case recommendation }
struct PestCareGuidanceFlow: View {
    @Environment(BloomStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let observationID: UUID
    var replacing: UUID? = nil
    var justSaved = false
    var finish: (() -> Void)? = nil
    @State private var answers = PestAssessment()
    @State private var path: [GuidancePage] = []
    @State private var initialized = false
    @State private var message: String?
    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if let observation = store.record(observationID), let plant = store.plant(observation.plantID) {
                    Form {
                        Section {
                            if justSaved { Label("Change saved", systemImage: "checkmark.circle.fill").foregroundStyle(BloomTheme.teal) }
                            BloomPlantIdentity(plant: plant)
                            Text(observation.observation).font(BloomType.section)
                            Text("These checks are optional. Unknown answers keep the inspection route available.").font(BloomType.body).foregroundStyle(.secondary)
                        }
                        Section {
                            Picker("Visible signs", selection: $answers.signs) {
                                Text("Not checked").tag(PestSigns?.none)
                                ForEach(PestSigns.allCases) { Text($0.rawValue).tag(Optional($0)).accessibilityIdentifier("assessment-sign-\($0.rawValue)") }
                            }.pickerStyle(.menu).accessibilityIdentifier("assessment-signs")
                        } header: { Text("What can you see?") }
                        Section("A little more detail") {
                            Picker("Where?", selection: $answers.location) {
                                Text("Not checked").tag(PestLocation?.none)
                                ForEach(PestLocation.allCases) { Text($0.rawValue).tag(Optional($0)) }
                            }.accessibilityIdentifier("assessment-location")
                            Picker("How widespread?", selection: $answers.extent) {
                                Text("Not checked").tag(PestExtent?.none)
                                ForEach(PestExtent.allCases) { Text($0.rawValue).tag(Optional($0)) }
                            }.accessibilityIdentifier("assessment-extent")
                            Picker("Plant placement", selection: $answers.placement) {
                                Text("Not checked").tag(AssessmentPlacement?.none)
                                ForEach(AssessmentPlacement.allCases) { Text($0.rawValue).tag(Optional($0)) }
                            }.accessibilityIdentifier("assessment-placement")
                        }
                        if let message { Section { Text(message).foregroundStyle(.red) } }
                    }.bloomNativeForm().navigationTitle("Take a closer look").navigationBarTitleDisplayMode(.inline)
                        .bloomNativeFooter {
                            BloomPrimaryAction(title: "See suggested steps") {
                                if store.saveAssessment(answers, observationID: observationID) {
                                    message = nil; path.append(.recommendation)
                                }
                            }.accessibilityIdentifier("assessment-continue")
                        }
                } else { ContentUnavailableView("Observation unavailable", systemImage: "leaf") }
            }
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close", systemImage: "xmark") { if let finish { finish() } else { dismiss() } }.labelStyle(.iconOnly) } }
            .navigationDestination(for: GuidancePage.self) { _ in
                recommendation
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
                Text(answers.recommendation.title).bloomHeading(BloomTheme.heading)
                Text(answers.recommendation.explanation).foregroundStyle(.secondary)
            }
            Section("Your starting steps") {
                ForEach(answers.recommendation.actionSteps, id: \.self) { step in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(step.title).font(BloomType.section)
                        LeafVisualSteps(step: step)
                        DisclosureGroup("Details and materials") {
                            Text(step.materials).font(BloomType.body)
                            ForEach(step.instructions, id: \.self) { Text($0).font(BloomType.body) }
                        }
                    }

                }
            }
            Section("What to look for") { Text(answers.recommendation.improvement) }
            CareGuidanceSourceSection(kind: answers.recommendation)
            if let message { Section { Text(message).foregroundStyle(.red) } }
        }.listStyle(.insetGrouped).bloomNativeForm().navigationTitle("What could help").navigationBarTitleDisplayMode(.inline)
            .bloomNativeFooter {
                BloomPrimaryAction(title: replacing == nil ? "Add to care plan" : "Update care plan") {
                    if let id = store.startCarePlan(observationID: observationID, answers: answers, reviewDays: nil, replacing: replacing) {
                        store.announceCarePlan(id); BloomFeedback.success()
                        if let finish { finish() } else { dismiss() }
                    } else { message = "The plan couldn't be started. Your observation is still saved." }
                }.accessibilityIdentifier("start-care-plan")
            }
    }

}

struct CareGuidanceSourceSection: View {
    var kind: CarePlanKind = .inspection
    private var sources: [(String, String)] { kind.isLeafGuidance ? LeafCareSources.sources : CareGuidanceSources.sources }
    var body: some View {
        Section {
            ForEach(sources, id: \.1) { source in Link(source.0, destination: URL(string: source.1)!) }
        } header: { Text("Why these steps?") } footer: {
            Text("Sourced starting steps, not a diagnosis. Check-in dates help you compare progress; they do not predict recovery.")
        }
    }
}
