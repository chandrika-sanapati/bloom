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
    @State private var reviewReceipt: PlanTaskReceipt?
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
                    if let reviewReceipt {
                        PlanProgressResultView(receipt: reviewReceipt, finish: { dismiss() })
                    } else if completedReceipt != nil {
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
                        pendingTask(task, plan: plan, plant: plant)
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
    private func pendingTask(_ task: PlanTask, plan: CarePlan, plant: Plant) -> some View {
        BloomContentPage {
            BloomPlantIdentity(plant: plant)
            if task.step == .review {
                if isEarlyReview {
                    Text("Checking early keeps your scheduled check-in.").font(BloomType.supporting)
                        .foregroundStyle(BloomTone.yellow.ink).padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(BloomTone.yellow.surface, in: RoundedRectangle(cornerRadius: 16))
                }
                comparison(plan)
            } else {
                Text(task.step.title).bloomHeading()
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(Array(task.step.instructions.enumerated()), id: \.offset) { index, instruction in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)").font(BloomType.section).foregroundStyle(BloomTheme.teal)
                                .frame(width: 38, height: 38).background(BloomTheme.selected, in: RoundedRectangle(cornerRadius: 12))
                            Text(instruction).font(BloomType.body).foregroundStyle(BloomTheme.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }.accessibilityElement(children: .combine)
                    }
                    DisclosureGroup("Materials") { Text(task.step.materials).font(BloomType.body) }
                }.bloomCard(padding: 16)
                if task.step == .waterDryRoots {
                    Text("What did you decide after checking?").bloomHeading()
                    BloomChoiceList(values: [CareAction.watered, .waited], selection: $wateringDecision,
                                    title: { $0.rawValue }, identifier: { "watering-decision-\($0.rawValue)" })
                        .accessibilityIdentifier("leaf-watering-decision")
                }
                noteField("What did you notice or do? · Optional")
                DisclosureGroup("Change the date or task") {
                    VStack(alignment: .leading, spacing: 14) {
                        Toggle("I did this earlier", isOn: $earlier)
                        if earlier { DatePicker("Completed", selection: $performedAt, in: ...Date(), displayedComponents: [.date, .hourAndMinute]) }
                        Button("Reschedule or set notification") { scheduling = true }.accessibilityIdentifier("reschedule-plan-task")
                        Button("Skip this action") { skipping = true }.accessibilityIdentifier("skip-plan-action")
                    }.padding(.top, 12)
                }
            }
            if let message { Text(message).font(BloomType.supporting).foregroundStyle(.red) }
        }.navigationTitle(task.step == .review ? "Check progress" : "Care action").navigationBarTitleDisplayMode(.inline)
            .bloomNativeFooter {
                VStack(spacing: 8) {
                    if task.step == .review && outcome == nil || task.step == .waterDryRoots && wateringDecision == nil { BloomSelectionHint() }
                    BloomPrimaryAction(title: task.step == .review ? "Save check-in" : "Complete action") { finish(task, skipped: false) }
                        .disabled(photoLoading || task.step == .review && outcome == nil || task.step == .waterDryRoots && wateringDecision == nil)
                        .accessibilityIdentifier("finish-plan-task")
                }
            }
    }
    private func noteField(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(BloomType.supporting).foregroundStyle(BloomTheme.secondary)
            TextField("Add a note", text: $note, axis: .vertical).lineLimit(3...6).bloomInput()
                .accessibilityIdentifier("plan-task-note")
        }
    }
    @ViewBuilder private func comparison(_ plan: CarePlan) -> some View {
        Text("Your starting observation").bloomHeading()
        VStack(alignment: .leading, spacing: 8) {
            Text(plan.baseline.observation).font(BloomType.section)
            Text(plan.baseline.date, format: .dateTime.month(.abbreviated).day().year()).font(BloomType.supporting).foregroundStyle(.secondary)
            if let data = plan.baseline.photo, let image = UIImage(data: data) { Image(uiImage: image).resizable().scaledToFit().accessibilityLabel("Before photo") }
        }.bloomCard(padding: 16)
        Text("What do you notice now?").bloomHeading()
        BloomChoiceList(values: [PlanOutcome.fewer, .same, .worse, .unclear],
                        selection: Binding(get: { outcome == PlanOutcome.none ? .fewer : outcome }, set: { outcome = $0 }),
                        title: { $0 == .fewer ? "Better" : $0 == .same ? "Same" : $0 == .worse ? "Worse" : "Not sure yet" },
                        identifier: { $0 == .unclear ? "progress-unsure" : "progress-\($0.rawValue)" })
        if outcome == .fewer || outcome == PlanOutcome.none {
            Toggle(PlanOutcome.none.title(for: plan.kind), isOn: Binding(get: { outcome == PlanOutcome.none }, set: { outcome = $0 ? PlanOutcome.none : .fewer }))
                .accessibilityIdentifier("progress-no-new-signs").padding(16)
                .background(BloomTheme.surface, in: RoundedRectangle(cornerRadius: 16))
        }
        noteField("Add a note · Optional")
        PhotosPicker(selection: $selectedPhoto, matching: .images) { Text("Add a comparison photo").frame(maxWidth: .infinity, minHeight: 44, alignment: .leading) }
            .buttonStyle(.bordered).disabled(photoLoading)
        if photoLoading { ProgressView("Opening photo…") }
        if let photo, let image = UIImage(data: photo) {
            Image(uiImage: image).resizable().scaledToFit().accessibilityLabel("Current photo")
            Button("Remove photo", role: .destructive) { self.photo = nil }
        }
        DisclosureGroup("What to compare") {
            VStack(alignment: .leading, spacing: 12) {
                Text(plan.kind.improvement).font(BloomType.body)
                ForEach(store.tasks(for: plan.id).filter { $0.step != .review }) { action in
                    LabeledContent(action.step.title, value: action.status.displayTitle).font(BloomType.body)
                }
            }.padding(.top, 12)
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
            BloomFeedback.success()
            if task.step != .review { store.announceCareTask(result) }
            else { store.careFeedback = nil }
            let remaining = store.tasks(for: task.planID).filter { $0.step != .review && $0.isOpen }
            if task.step == .review { reviewReceipt = result }
            else if !skipped && remaining.isEmpty,
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

/// A saved comparison has an explicit next step, rather than disappearing into a banner.
private struct PlanProgressResultView: View {
    @Environment(BloomStore.self) private var store
    let receipt: PlanTaskReceipt
    var finish: () -> Void
    @State private var resolving = false
    @State private var reassessing = false
    @State private var scheduling = false
    @State private var scheduleSaved = false
    private var plan: CarePlan? { store.carePlan(receipt.task.planID) }
    var body: some View {
        Group {
            if let plan, let record = store.record(receipt.recordID), let plant = store.plant(plan.plantID) {
                BloomContentPage {
                    Label("Check-in saved", systemImage: "checkmark.circle.fill")
                        .font(BloomType.section).foregroundStyle(BloomTheme.teal).accessibilityIdentifier("care-feedback-title")
                    BloomPlantIdentity(plant: plant)
                    Text(plan.status == .needsReview ? "Take another look" : PlanOutcome.fromStored(record.outcome) == .same ? "Keep the issue open" : "A good sign. Keep observing.").bloomHeading(BloomType.title)
                    Text(plan.status == .needsReview ? "The result is unclear or worse. Review the evidence before choosing another action." : "Completing care and noticing improvement don't automatically resolve the issue.")
                        .font(BloomType.supporting).foregroundStyle(BloomTheme.secondary)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(record.outcome).font(BloomType.section)
                        if !record.note.isEmpty { Text(record.note).font(BloomType.body) }
                    }.bloomCard(padding: 16)
                    VStack(spacing: 0) {
                        if store.planIsOpen(plan.id) && PlanOutcome.fromStored(record.outcome) == PlanOutcome.none {
                            Button { resolving = true } label: { BloomActionRow(title: "Mark issue as resolved") }
                                .accessibilityIdentifier("resolve-after-check").padding(16)
                            Divider().padding(.leading, 16)
                        }
                        if plan.status == .needsReview {
                            Button { reassessing = true } label: { BloomActionRow(title: "Review next step") }
                                .accessibilityIdentifier("reassess-after-check").padding(16)
                            Divider().padding(.leading, 16)
                        }
                        NavigationLink { CarePlanDetailView(planID: plan.id) } label: {
                            BloomActionRow(title: plan.status == .needsReview ? "Review care plan" : "View care plan")
                        }.accessibilityIdentifier("view-care-plan").padding(16)
                        if store.planIsOpen(plan.id) {
                            Divider().padding(.leading, 16)
                            Button { scheduleSaved = false; scheduling = true } label: { BloomActionRow(title: "Choose another check-in") }
                                .accessibilityIdentifier("schedule-after-check").padding(16)
                        }
                        Divider().padding(.leading, 16)
                        NavigationLink { RecordDetailView(recordID: record.id) } label: { BloomActionRow(title: "View your record") }.padding(16)
                    }.buttonStyle(.plain).background(BloomTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                }.navigationTitle("Check-in saved").navigationBarTitleDisplayMode(.inline)
                    .bloomNativeFooter { BloomPrimaryAction(title: "Back to care", action: finish).accessibilityIdentifier("finish-progress-result") }
                    .sheet(isPresented: $scheduling, onDismiss: { if scheduleSaved { finish() } }) {
                        PlanReviewScheduleView(planID: plan.id, saved: { scheduleSaved = true })
                    }
                    .fullScreenCover(isPresented: $reassessing, onDismiss: {
                        if let current = store.plan(for: plan.observationID), current.id != plan.id { finish() }
                    }) { CareGuidanceFlow(observationID: plan.observationID, replacing: plan.id) }
                    .confirmationDialog("Mark this issue as resolved?", isPresented: $resolving, titleVisibility: .visible) {
                        Button("Mark resolved") {
                            if store.closePlan(plan.id, resolved: true) {
                                store.careFeedback = CareFlowFeedback(plantID: plan.plantID, title: "Issue resolved", detail: "Your observations and care steps stay in Activity.")
                                finish()
                            }
                        }
                    } message: { Text("This records your decision and cancels this plan's pending tasks. Your history stays saved.") }
            }
        }
    }
}
