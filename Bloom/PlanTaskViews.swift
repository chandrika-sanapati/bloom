import SwiftUI
import PhotosUI

struct PlanTaskFlowView: View {
    @Environment(BloomStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let taskID: UUID
    @State private var receipt: PlanTaskReceipt?
    @State private var note = ""
    @State private var earlier = false
    @State private var performedAt = Date()
    @State private var outcome: PlanOutcome?
    @State private var photo: Data?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoLoading = false
    @State private var message: String?
    @State private var scheduling = false
    @State private var skipping = false
    @State private var reassessing = false
    @State private var resolving = false
    private var task: PlanTask? { store.careTask(taskID) }
    private var plan: CarePlan? { task.flatMap { store.carePlan($0.planID) } }
    var body: some View {
        NavigationStack {
            Group {
                if let receipt, let record = store.record(receipt.recordID), let plan { confirmation(record, plan: plan, receipt: receipt) }
                else if let task, let plan, let plant = store.plant(task.plantID) {
                    if task.status == .pending && store.planIsOpen(plan.id) {
                        Form {
                            Section {
                                BloomPlantIdentity(plant: plant)
                                Text(plan.kind.title).font(.headline)
                                if let due = task.due { Text("Scheduled: \(due.formatted(date: .abbreviated, time: .shortened))").font(.subheadline).foregroundStyle(.secondary) }
                            }
                            if task.step == .review { comparison(plan) }
                            else {
                                Section("What you'll need") { Text(task.step.materials) }
                                Section("How to do it") {
                                    ForEach(Array(task.step.instructions.enumerated()), id: \.offset) { index, instruction in
                                        HStack(alignment: .top, spacing: 10) {
                                            Text("\(index + 1)").font(.subheadline.weight(.semibold)).foregroundStyle(BloomTheme.teal)
                                            Text(instruction).fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                }
                            }
                            if task.step != .review {
                                Section {
                                    Toggle("I did this earlier", isOn: $earlier)
                                    if earlier { DatePicker("Completed", selection: $performedAt, in: ...Date(), displayedComponents: [.date, .hourAndMinute]) }
                                } footer: { Text("The progress check uses the completion time you record.") }
                            }
                            Section("Notes · Optional") { TextField("What did you notice or do?", text: $note, axis: .vertical).lineLimit(3...6) }
                            Section {
                                Button("Reschedule or set notification", systemImage: "calendar") { scheduling = true }.accessibilityIdentifier("reschedule-plan-task")
                                if task.step != .review { Button("Skip this action", systemImage: "forward") { skipping = true }.accessibilityIdentifier("skip-plan-action") }
                            }
                            if let message { Section { Text(message).font(.footnote).foregroundStyle(.red) } }
                        }.bloomNativeForm().navigationTitle(task.step == .review ? "Check progress" : "Care action").navigationBarTitleDisplayMode(.inline)
                            .bloomNativeFooter {
                                BloomPrimaryAction(title: task.step == .review ? "Save check-in" : "Mark action done", symbol: "checkmark") { finish(task, skipped: false) }
                                    .disabled(photoLoading || task.step == .review && outcome == nil).accessibilityIdentifier("finish-plan-task")
                            }
                    } else {
                        List {
                            Section {
                                BloomPlantIdentity(plant: plant)
                                Text(task.step.title).font(.headline)
                                StatusTag(text: task.status.rawValue, tone: .teal)
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
                    Button(receipt == nil ? "Close" : "Done") { dismiss() }.accessibilityIdentifier("close-plan-task")
                }
            }
        }
        .sheet(isPresented: $scheduling) { PlanTaskScheduleView(taskID: taskID) }
        .sheet(isPresented: $reassessing) { if let plan { CareGuidanceFlow(observationID: plan.observationID, replacing: plan.id) } }
        .confirmationDialog("Skip this action?", isPresented: $skipping, titleVisibility: .visible) {
            Button("Skip action") { if let task { finish(task, skipped: true) } }
        } message: { Text("It will be recorded as skipped, not as treatment completed. If every action is skipped, no progress timer starts.") }
        .confirmationDialog("Mark this issue as resolved?", isPresented: $resolving, titleVisibility: .visible) {
            Button("Mark resolved") { if let plan { _ = store.closePlan(plan.id, resolved: true) } }
        } message: { Text("This records your decision after the check-in, and cancels any pending tasks for this plan.") }
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
                Text(plan.baseline.observation).font(.headline)
                Text(plan.baseline.date, format: .dateTime.month(.abbreviated).day().year()).font(.caption).foregroundStyle(.secondary)
                if let data = plan.baseline.photo, let image = UIImage(data: data) { Image(uiImage: image).resizable().scaledToFit().accessibilityLabel("Before photo") }
            }
            Section("What you recorded doing") {
                ForEach(store.tasks(for: plan.id).filter { $0.step != .review }) { action in
                    LabeledContent(action.step.title, value: action.status.rawValue)
                }
            }
            Section { Text(plan.kind.improvement).font(.subheadline) }
            Section {
                Picker("Progress", selection: $outcome) {
                    Text("Choose what you see").tag(PlanOutcome?.none)
                    ForEach(PlanOutcome.allCases) { Text($0.rawValue).tag(Optional($0)) }
                }.pickerStyle(.inline)
            } header: { Text("What do you notice now?") }
            Section("Photo now · Optional") {
                PhotosPicker(selection: $selectedPhoto, matching: .images) { Label("Add a comparison photo", systemImage: "photo") }.disabled(photoLoading)
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
        if task.step == .review, let outcome { result = store.finishPlanReview(taskID: task.id, outcome: outcome, note: note, photo: photo) }
        else { result = store.finishPlanAction(taskID: task.id, skipped: skipped, note: note, now: earlier && !skipped ? performedAt : .now) }
        if let result { receipt = result; BloomFeedback.success() }
        else { message = "This task couldn't be saved. Your previous records are unchanged." }
    }
    private func confirmation(_ record: CareRecord, plan: CarePlan, receipt: PlanTaskReceipt) -> some View {
        List {
            Section {
                Label(record.kind == .followUp ? "Check-in saved" : record.outcome == "Skipped" ? "Action skipped" : "Action recorded", systemImage: "checkmark.circle.fill")
                    .font(.title2.weight(.semibold)).foregroundStyle(BloomTheme.teal).accessibilityIdentifier("plan-task-saved")
                Text(record.kind == .followUp ? record.outcome : record.actionTitle ?? "Care action").font(.headline)
                if record.kind == .followUp {
                    Text(record.outcome == PlanOutcome.worse.rawValue || record.outcome == PlanOutcome.unclear.rawValue ? "Let's reassess the evidence before choosing further treatment." : record.outcome == PlanOutcome.none.rawValue ? "No visible signs is encouraging. You decide whether to mark the issue resolved; Bloom won't close it automatically." : "Your comparison is saved. Keep watching for new signs before deciding whether another action is needed.").foregroundStyle(.secondary)
                } else if let review = store.tasks(for: plan.id).first(where: { $0.step == .review && $0.status == .pending }), let due = review.due {
                    Text("Progress check: \(due.formatted(date: .abbreviated, time: .shortened))").foregroundStyle(.secondary)
                } else { Text("Your action is saved in Activity. Any automatic progress check waits until the remaining actions are recorded.").foregroundStyle(.secondary) }
            }
            Section {
                NavigationLink("View care plan") { CarePlanDetailView(planID: plan.id) }
                if store.canUndoPlanTask(receipt) {
                    Button("Undo", systemImage: "arrow.uturn.backward") { if store.undoPlanTask(receipt) { dismiss() } }.accessibilityIdentifier("undo-plan-task")
                }
                if record.kind == .followUp && store.planIsOpen(plan.id) {
                    Button("Reassess this plan", systemImage: "arrow.triangle.2.circlepath") { reassessing = true }.accessibilityIdentifier("reassess-after-check")
                    if record.outcome == PlanOutcome.none.rawValue { Button("Mark issue as resolved", systemImage: "checkmark.seal") { resolving = true }.accessibilityIdentifier("resolve-after-check") }
                }
            }
        }.listStyle(.insetGrouped).bloomNativeForm().navigationTitle("Saved").navigationBarTitleDisplayMode(.inline)
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
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
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
