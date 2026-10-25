import SwiftUI
import PhotosUI

struct PlanTaskFlowView: View {
    @Environment(BloomStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let taskID: UUID
    @State private var note = ""
    @State private var earlier = false
    @State private var performedAt = Date()
    @State private var outcome: PlanOutcome?
    @State private var wateringDecision: CareAction?
    @State private var photo: Data?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoLoading = false
    @State private var message: String?
    @State private var scheduling = false
    @State private var skipping = false
    @State private var completedReceipt: PlanTaskReceipt?
    @State private var reviewDate = Date()
    private var task: PlanTask? { store.careTask(taskID) }
    private var isEarlyReview: Bool {
        guard let task, task.step == .review else { return false }
        return (task.due ?? .distantPast) > Date()
    }
    private var plan: CarePlan? { task.flatMap { store.carePlan($0.planID) } }
    var body: some View {
        NavigationStack {
            Group {
                if let task, let plan, let plant = store.plant(task.plantID) {
                    if completedReceipt != nil {
                        Form {
                            Section {
                                BloomPlantIdentity(plant: plant)
                                Text("Action recorded").font(BloomType.title).accessibilityIdentifier("action-completion-title")
                                Text("Your care record is saved.").font(BloomType.body).foregroundStyle(.secondary)
                            }
                            Section("Check progress later?") {
                                DatePicker("Check-in date", selection: $reviewDate, in: Date()..., displayedComponents: .date)
                                Text("Compare with your original observation. This is a check-in, not a recovery deadline.")
                                    .font(BloomType.supporting).foregroundStyle(.secondary)
                            }
                            if let message { Text(message).foregroundStyle(.red) }
                        }.bloomNativeForm().navigationTitle("Next step").navigationBarTitleDisplayMode(.inline)
                            .bloomNativeFooter {
                                VStack(spacing: 8) {
                                    BloomPrimaryAction(title: "Schedule check-in") {
                                        if store.schedulePlanReview(plan.id, date: reviewDate) {
                                            store.careFeedback?.detail = "Check again \(reviewDate.formatted(date: .abbreviated, time: .omitted))."
                                            dismiss()
                                        } else { message = "Choose a future date to schedule your check-in." }
                                    }.accessibilityIdentifier("schedule-completion-check-in")
                                    Button("Not now") { dismiss() }.frame(minHeight: 44).accessibilityIdentifier("skip-completion-check-in")
                                }
                            }
                    } else if task.status == .pending && store.planIsOpen(plan.id) {
                        Form {
                            Section {
                                VStack(alignment: .leading, spacing: 10) {
                                    BloomPlantIdentity(plant: plant)
                                    if task.step != .review { Text(task.step.title).font(BloomType.section) }
                                    if let due = task.due {
                                        Text(task.customDate ? "Scheduled: \(due.formatted(date: .abbreviated, time: .shortened))" : Calendar.current.isDateInToday(due) ? "Today" : "\(task.step == .review ? "Check-in" : "Due"): \(due.formatted(date: .abbreviated, time: .omitted))")
                                            .font(BloomType.body).foregroundStyle(.secondary)
                                    }
                                    if task.step == .review && isEarlyReview {
                                        Label("Checking early keeps your scheduled check-in.", systemImage: "calendar").font(BloomType.supporting).foregroundStyle(.secondary)
                                    }
                                }.padding(.vertical, 2)
                            }
                            if task.step == .review {
                                comparison(plan)
                            }
                            else {
                                Section("Your next step") {
                                    LeafVisualSteps(step: task.step)
                                    DisclosureGroup("Details and materials") {
                                        Text(task.step.materials).font(BloomType.section)
                                        ForEach(task.step.instructions, id: \.self) { Text($0).font(BloomType.body) }
                                    }
                                }
                            }
                            if task.step == .waterDryRoots {
                                Section("What did you decide after checking?") {
                                    Picker("Watering decision", selection: $wateringDecision) {
                                        Text("Choose what you did").tag(CareAction?.none)
                                        Text("I watered after checking").tag(Optional(CareAction.watered))
                                        Text("I checked and chose to wait").tag(Optional(CareAction.waited))
                                    }.pickerStyle(.inline).accessibilityIdentifier("leaf-watering-decision")
                                }
                            }
                            Section {
                                DisclosureGroup("Add a note or change the date") {
                                    TextField("What did you notice or do?", text: $note, axis: .vertical).lineLimit(2...4)
                                    if task.step != .review {
                                        Toggle("I did this earlier", isOn: $earlier)
                                        if earlier { DatePicker("Completed", selection: $performedAt, in: ...Date(), displayedComponents: [.date, .hourAndMinute]) }
                                    }
                                    Button("Reschedule or set notification") { scheduling = true }.accessibilityIdentifier("reschedule-plan-task")
                                    if task.step != .review { Button("Skip this action") { skipping = true }.accessibilityIdentifier("skip-plan-action") }
                                }
                            }
                            if let message { Section { Text(message).font(BloomType.supporting).foregroundStyle(.red) } }
                        }.bloomNativeForm().listSectionSpacing(16)
                            .contentMargins(.top, 12, for: .scrollContent)
                            .navigationTitle(task.step == .review ? "Check progress" : "Care action").navigationBarTitleDisplayMode(.inline)
                            .bloomNativeFooter {
                                BloomPrimaryAction(title: task.step == .review ? "Save check-in" : "Complete action") { finish(task, skipped: false) }
                                    .disabled(photoLoading || task.step == .review && outcome == nil || task.step == .waterDryRoots && wateringDecision == nil).accessibilityIdentifier("finish-plan-task")
                            }
                    } else {
                        List {
                            Section {
                                BloomPlantIdentity(plant: plant)
                                Text(task.step.title).font(BloomType.section)
                                StatusTag(text: task.status.displayTitle, tone: .teal)
                                if task.status == .waiting { Text("Record the plan's actions before its progress check is scheduled.").foregroundStyle(.secondary) }
                                NavigationLink("View care plan") { CarePlanDetailView(planID: plan.id) }
                            }
                            if let record = store.garden.records.first(where: { $0.planTaskID == task.id }) {
                                Section { Text(record.outcome); if !record.note.isEmpty { Text(record.note) } }
                            }
                        }.listStyle(.insetGrouped).bloomNativeForm().navigationTitle("Care task").navigationBarTitleDisplayMode(.inline)
                    }
                } else { ContentUnavailableView("Task unavailable", systemImage: "checkmark.circle", description: Text("The task or its observation may have been removed.")) }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }.labelStyle(.iconOnly).accessibilityIdentifier("close-plan-task")
                }
            }
        }
        .sheet(isPresented: $scheduling) { PlanTaskScheduleView(taskID: taskID) }
        .confirmationDialog("Skip this action?", isPresented: $skipping, titleVisibility: .visible) {
            Button("Skip action") { if let task { finish(task, skipped: true) } }
        } message: { Text("It will be recorded as skipped, not as treatment completed. If every action is skipped, no progress timer starts.") }
        .onAppear { store.careFeedback = nil }
        .onChange(of: selectedPhoto) { _, selected in
            guard let selected else { return }; photoLoading = true; message = nil
            Task {
                do {
                    guard let bytes = try await selected.loadTransferable(type: Data.self), let image = UIImage(data: bytes),
                          let compressed = image.preparingThumbnail(of: CGSize(width: 1200, height: 1200))?.jpegData(compressionQuality: 0.8) else { throw CocoaError(.fileReadCorruptFile) }
                    photo = compressed
                } catch { message = "This photo couldn't be opened. Please choose another." }
                selectedPhoto = nil; photoLoading = false
            }
        }
    }
    private func comparison(_ plan: CarePlan) -> some View {
        Group {
            Section("Your starting observation") {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.baseline.observation).font(BloomType.section)
                    Text(plan.baseline.date, format: .dateTime.month(.abbreviated).day().year()).font(BloomType.supporting).foregroundStyle(.secondary)
                }.padding(.vertical, 2)
                if let data = plan.baseline.photo, let image = UIImage(data: data) { Image(uiImage: image).resizable().scaledToFit().accessibilityLabel("Before photo") }
            }
            Section("What do you notice now?") {
                VStack(spacing: 4) {
                    ForEach([PlanOutcome.fewer, .same, .worse, .unclear], id: \.self) { value in
                        let selected = outcome == value || value == .fewer && outcome == PlanOutcome.none
                        Button { outcome = value; BloomFeedback.selection() } label: {
                            HStack(spacing: 10) {
                                BloomSymbol(name: value == .fewer ? "leaf" : value == .same ? "equal" : value == .worse ? "exclamationmark.triangle" : "questionmark.circle")
                                    .foregroundStyle(value == .worse ? BloomTone.yellow.ink : selected ? BloomTheme.teal : BloomTheme.secondary)
                                Text(value == .fewer ? "Better" : value == .same ? "Same" : value == .worse ? "Worse" : "Not sure yet")
                                    .font(.body.weight(selected ? .semibold : .regular)).foregroundStyle(BloomTheme.ink)
                                Spacer(minLength: 8)
                                BloomSymbol(name: selected ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selected ? BloomTheme.teal : BloomTheme.secondary)
                            }.padding(.horizontal, 12).padding(.vertical, 10)
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                .background(selected ? BloomTheme.selected : Color.clear, in: RoundedRectangle(cornerRadius: 12))
                                .contentShape(RoundedRectangle(cornerRadius: 12))
                        }.buttonStyle(.plain)
                            .accessibilityIdentifier(value == .unclear ? "progress-unsure" : "progress-\(value.rawValue)")
                            .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }.listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                if outcome == .fewer || outcome == PlanOutcome.none {
                    Toggle(PlanOutcome.none.title(for: plan.kind), isOn: Binding(get: { outcome == PlanOutcome.none }, set: { outcome = $0 ? PlanOutcome.none : .fewer }))
                        .accessibilityIdentifier("progress-no-new-signs")
                }
            }
            Section {
                DisclosureGroup("What to compare") {
                    Text(plan.kind.improvement).font(BloomType.body)
                    ForEach(store.tasks(for: plan.id).filter { $0.step != .review }) { action in
                        LabeledContent(action.step.title, value: action.status.displayTitle).font(BloomType.body)
                    }
                }
            }
            Section("Photo now · Optional") {
                PhotosPicker(selection: $selectedPhoto, matching: .images) { Text("Add a comparison photo") }.disabled(photoLoading)
                if photoLoading { ProgressView("Opening photo…") }
                if let photo, let image = UIImage(data: photo) {
                    Image(uiImage: image).resizable().scaledToFit().accessibilityLabel("Current photo")
                    Button("Remove photo", role: .destructive) { self.photo = nil }
                }
            }
        }
    }
    private func finish(_ task: PlanTask, skipped: Bool) {
        let result: PlanTaskReceipt?
        if task.step == .review, let outcome {
            // An early comparison is a separate record; the planned follow-up stays scheduled.
            let reviewID = isEarlyReview ? store.reviewPlanNow(task.planID) : task.id
            if let reviewID { result = store.finishPlanReview(taskID: reviewID, outcome: outcome, note: note, photo: photo) }
            else { result = nil }
        } else { result = store.finishPlanAction(taskID: task.id, skipped: skipped, note: note, now: earlier && !skipped ? performedAt : .now, wateringAction: wateringDecision) }
        if let result {
            store.announceCareTask(result); BloomFeedback.success()
            let remaining = store.tasks(for: task.planID).filter { $0.step != .review && $0.isOpen }
            if task.step != .review && !skipped && remaining.isEmpty,
               !store.tasks(for: task.planID).contains(where: { $0.step == .review && $0.status == .pending }) {
                reviewDate = Calendar.current.date(byAdding: .day, value: plan?.kind.defaultReviewDays ?? 3, to: Date()) ?? Date().addingTimeInterval(259200)
                completedReceipt = result
            } else { dismiss() }
        }
        else { message = "This task couldn't be saved. Your previous records are unchanged." }
    }

}

struct PlanTaskScheduleView: View {
    @Environment(BloomStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let taskID: UUID
    @State private var date = Date().addingTimeInterval(86400)
    @State private var notify = false
    @State private var busy = false
    @State private var saved = false
    @State private var message: String?
    var body: some View {
        NavigationStack {
            Form {
                Section { DatePicker("Task date", selection: $date, in: Date()..., displayedComponents: [.date, .hourAndMinute]) }
                Section {
                    Toggle("Notify me", isOn: $notify)
                } footer: { Text("Your task stays in Bloom even if notifications are off.") }
                if let message { Section { Text(message).foregroundStyle(.secondary) } }
            }.bloomNativeForm().navigationTitle("Task schedule").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel", systemImage: "xmark") { dismiss() }.labelStyle(.iconOnly) }
                    ToolbarItem(placement: .confirmationAction) { Button(saved ? "Done" : "Save") {
                        if saved { dismiss(); return }
                        guard store.reschedulePlanTask(taskID, date: date) else { message = "Choose a future date for an open task."; return }
                        busy = true
                        Task {
                            if notify { message = await store.enablePlanNotification(taskID) }
                            else { _ = store.disablePlanNotification(taskID); message = nil }
                            busy = false; saved = true
                            if message == nil { dismiss() }
                        }
                    }.disabled(busy) }
                }
        }.onAppear {
            if let task = store.careTask(taskID) { date = max(task.due ?? date, Date().addingTimeInterval(60)); notify = task.notifications }
        }
    }
}
