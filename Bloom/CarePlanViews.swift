import SwiftUI
import PhotosUI

struct CarePlanDetailView: View {
    @Environment(BloomStore.self) private var store
    let planID: UUID
    @State private var task: PlanTaskRoute?
    @State private var reassessing = false
    @State private var stopping = false
    @State private var resolving = false
    @State private var scheduling = false
    private var plan: CarePlan? { store.carePlan(planID) }
    private var lastReview: CareRecord? { store.garden.records.filter { $0.planID == planID && $0.kind == .followUp }.max { $0.date < $1.date } }
    var body: some View {
        Group {
            if let plan, let plant = store.plant(plan.plantID) {
                List {
                    Section {
                        BloomPlantIdentity(plant: plant)
                        StatusTag(text: plan.status.rawValue, tone: plan.status == .needsReview ? .yellow : .teal)
                        Text(plan.kind.title).font(BloomType.title)
                        Text(plan.kind.explanation).font(BloomType.body).foregroundStyle(.secondary)
                    }
                    if plan.status == .needsReview {
                        Section { InfoCard(title: "Let's take another look", message: "The result is unclear, worse, or no actions were completed. Review the evidence before choosing further treatment.", icon: "magnifyingglass") }
                    }
                    if let checks = plan.leafAssessment {
                        Section {
                            DisclosureGroup("Checks behind this plan") {
                                ForEach(checks.summary, id: \.0) { LabeledContent($0.0, value: $0.1) }
                            }
                        }
                    }
                    Section("Actions") {
                        ForEach(store.tasks(for: planID).filter { $0.step != .review }) { item in taskButton(item) }
                    }
                    Section("Check progress") {
                        ForEach(store.tasks(for: planID).filter { $0.step == .review && $0.isOpen }) { item in
                            if item.status == .waiting {
                                VStack(alignment: .leading, spacing: 6) {
                                    Label("After your actions", systemImage: "clock")
                                    Text("Your check-in will be scheduled \(plan.reviewAfterDays ?? plan.kind.defaultReviewDays) days after the actions are recorded. No recovery timer has started.").font(BloomType.body).foregroundStyle(.secondary)
                                }
                            } else { taskButton(item) }
                        }
                        if let lastReview { Text("Last check-in: \(lastReview.outcome)").font(BloomType.body) }
                        if store.planIsOpen(planID) && store.tasks(for: planID).contains(where: { $0.step != .review && $0.status == .completed }) {
                            Button("Record a check-in now") {
                                if let id = store.reviewPlanNow(planID) { task = PlanTaskRoute(id: id) }
                            }.accessibilityIdentifier("review-plan-now")
                            Button("Choose another check-in date") { scheduling = true }
                        }
                        Text(plan.kind.improvement).font(BloomType.body).foregroundStyle(.secondary)
                    }
                    Section("Your starting observation") {
                        Text(plan.baseline.observation).font(BloomType.section)
                        Text(plan.baseline.date, format: .dateTime.month(.abbreviated).day().year()).font(BloomType.supporting).foregroundStyle(.secondary)
                        if let data = plan.baseline.photo, let image = UIImage(data: data) { Image(uiImage: image).resizable().scaledToFit().accessibilityLabel("Original observation photo") }
                        NavigationLink("Open original record") { RecordDetailView(recordID: plan.observationID) }
                    }
                    if store.planIsOpen(planID) {
                        Section {
                            Button("Reassess this plan") { reassessing = true }.accessibilityIdentifier("reassess-plan")
                            if PlanOutcome.fromStored(lastReview?.outcome) == PlanOutcome.none {
                                Button("Mark issue as resolved") { resolving = true }.accessibilityIdentifier("resolve-plan")
                            }
                            Button("Stop this plan", role: .destructive) { stopping = true }
                        }
                    } else if let newer = store.plan(for: plan.observationID), newer.id != planID {
                        Section { NavigationLink("Open revised plan") { CarePlanDetailView(planID: newer.id) } }
                    }
                    CareGuidanceSourceSection(kind: plan.kind)
                }.listStyle(.insetGrouped).bloomNativeForm().navigationTitle("Care plan").navigationBarTitleDisplayMode(.inline)
            } else { ContentUnavailableView("Plan unavailable", systemImage: "leaf") }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { CareFeedbackBanner(plantID: plan?.plantID) }
        .sheet(item: $task) { PlanTaskFlowView(taskID: $0.id) }
        .sheet(isPresented: $reassessing) { if let plan { CareGuidanceFlow(observationID: plan.observationID, replacing: plan.id) } }
        .sheet(isPresented: $scheduling) { PlanReviewScheduleView(planID: planID) }
        .confirmationDialog("Stop this plan?", isPresented: $stopping, titleVisibility: .visible) {
            Button("Stop plan", role: .destructive) { _ = store.closePlan(planID, resolved: false) }
        } message: { Text("Pending tasks for this plan will be cancelled. Your observations and completed actions stay in Activity.") }
        .confirmationDialog("Mark this issue as resolved?", isPresented: $resolving, titleVisibility: .visible) {
            Button("Mark resolved") { _ = store.closePlan(planID, resolved: true) }
        } message: { Text("This records your decision after the latest check-in. Pending tasks for this plan will be cancelled.") }
    }
    private func taskButton(_ task: PlanTask) -> some View {
        Button { self.task = PlanTaskRoute(id: task.id) } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(task.step.title).foregroundStyle(BloomTheme.ink)
                    Spacer(minLength: 8)
                    StatusTag(text: task.status.displayTitle, tone: task.status == .completed ? .teal : task.step == .review ? .yellow : .blue)
                    BloomSymbol(name: "chevron.right", compact: true).foregroundStyle(BloomTheme.teal)
                }
                if let date = task.completedAt ?? task.due { Text(date.formatted(date: .abbreviated, time: .shortened)).font(BloomType.supporting).foregroundStyle(.secondary) }
            }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .padding(.vertical, 4).contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityIdentifier("plan-step-\(task.step.rawValue)")
    }
}

struct PlanReviewScheduleView: View {
    @Environment(BloomStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let planID: UUID
    @State private var date = Date().addingTimeInterval(604800)
    @State private var message: String?
    var body: some View {
        NavigationStack {
            Form {
                Section { DatePicker("Check progress", selection: $date, in: Date()..., displayedComponents: [.date, .hourAndMinute]) }
                Section { Text("This adds an inspection task in Bloom. It doesn't repeat a treatment or enable notifications.").foregroundStyle(.secondary) }
                if let message { Text(message).foregroundStyle(.red) }
            }.bloomNativeForm().navigationTitle("Next check-in").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Save") {
                        if store.schedulePlanReview(planID, date: date), let plan = store.carePlan(planID) {
                            store.careFeedback = CareFlowFeedback(plantID: plan.plantID, title: "Next check-in set", detail: "Check again \(date.formatted(date: .abbreviated, time: .omitted)).", planID: planID)
                            dismiss()
                        }
                        else { message = "Choose a future date after recording an action. Your plan is unchanged." }
                    } }
                }
        }.onAppear {
            let existing = store.tasks(for: planID).first { $0.step == .review && $0.status == .pending }?.due
            date = max(existing ?? Calendar.current.date(byAdding: .day, value: store.carePlan(planID)?.reviewAfterDays ?? 3, to: Date()) ?? date, Date().addingTimeInterval(60))
        }
    }
}

struct PlanRecordNoteEditor: View {
    @Environment(BloomStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let recordID: UUID
    @State private var note = ""
    var body: some View {
        NavigationStack {
            Form { TextField("What would you like to remember?", text: $note, axis: .vertical).lineLimit(4...10) }
                .bloomNativeForm().navigationTitle("Edit note").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Save") {
                        if var record = store.record(recordID) { record.note = note; if store.saveRecord(record) { dismiss() } }
                    } }
                }
        }.onAppear { note = store.record(recordID)?.note ?? "" }
    }
}
