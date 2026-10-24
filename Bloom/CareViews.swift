import SwiftUI
import UserNotifications

private enum CarePage: Hashable { case decide }

struct CareCheckView: View {
    @Environment(BloomStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let plantID: UUID
    var original: CareRecord? = nil
    @State private var draft: CareRecord?
    @State private var path: [CarePage] = []
    @State private var saved = false
    @State private var busy = false
    @State private var receipt: CareSaveReceipt?
    private var soil: Binding<Soil?> { Binding(get: { draft?.soil }, set: { draft?.soil = $0 }) }
    private var action: Binding<CareAction?> { Binding(get: { draft?.action }, set: { draft?.action = $0 }) }
    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if saved, let draft {
                    SavedRecordView(recordID: draft.id, edit: { saved = false; path = [] }, undo: undo, finish: { dismiss() })
                } else if let plant = store.plant(plantID) {
                    Form {
                        Section { BloomPlantIdentity(plant: plant) }
                        Section {
                            Picker("Soil", selection: soil) {
                                Text("Choose an observation").tag(Soil?.none)
                                ForEach(Soil.allCases) { Text($0.rawValue).tag(Optional($0)) }
                            }.pickerStyle(.inline)
                        } header: { Text("How does the soil feel?") } footer: { Text("Choose what you notice now. Not sure is a valid observation.") }
                        if let last = store.latestCheck(for: plantID) { Section("Last time") { Text(last.summary).foregroundStyle(.secondary) } }
                    }.bloomNativeForm().navigationTitle("Check soil").navigationBarTitleDisplayMode(.inline)
                        .bloomNativeFooter {
                            BloomPrimaryAction(title: "Continue") { path.append(.decide) }.disabled(draft?.soil == nil).accessibilityIdentifier("continue-check")
                        }
                } else { ContentUnavailableView("Plant unavailable", systemImage: "leaf") }
            }.toolbar { if !saved { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } } }
                .navigationDestination(for: CarePage.self) { _ in
                    if saved, let draft { SavedRecordView(recordID: draft.id, edit: { saved = false }, undo: undo, finish: { dismiss() }) }
                    else {
                        Form {
                            Section { LabeledContent("You observed", value: draft?.soil?.rawValue ?? "Not sure") }
                            Section {
                                Picker("Decision", selection: action) {
                                    Text("Choose your decision").tag(CareAction?.none)
                                    ForEach(CareAction.allCases) { Text($0.rawValue).tag(Optional($0)) }
                                }.pickerStyle(.inline)
                            } header: { Text("What did you do?") } footer: { Text("This records your choice. Waiting counts, too.") }
                            Section("Notes · Optional") {
                                TextField("Anything to remember?", text: Binding(get: { draft?.note ?? "" }, set: { draft?.note = $0 }), axis: .vertical).lineLimit(3...6).accessibilityIdentifier("check-note")
                            }
                        }.bloomNativeForm().navigationTitle("Your decision").navigationBarTitleDisplayMode(.inline)
                            .bloomNativeFooter {
                                BloomPrimaryAction(title: busy ? "Saving…" : "Save care", action: save)
                                    .disabled(draft?.action == nil || busy).accessibilityIdentifier("save-check")
                            }
                    }
                }
        }.onAppear { if draft == nil { draft = original ?? CareRecord(plantID: plantID, kind: .check) } }
    }
    private func save() {
        guard let draft else { return }; busy = true
        Task {
            if original != nil || receipt != nil {
                if store.saveRecord(draft) { saved = true; BloomFeedback.success() }
            } else if let result = await store.finishCare(draft) { receipt = result; saved = true; BloomFeedback.success() }
            busy = false
        }
    }
    private func undo() {
        guard let draft else { return }
        Task {
            let success: Bool
            if let receipt { success = await store.undoCare(receipt) }
            else { success = original.map { store.saveRecord($0) } ?? store.deleteRecord(draft.id) }
            if success { dismiss() }
        }
    }
}

struct SavedRecordView: View {
    @Environment(BloomStore.self) private var store
    let recordID: UUID
    var edit: () -> Void
    var undo: () -> Void
    var finish: () -> Void
    var nextSteps: (() -> Void)? = nil
    @State private var guidance: CareGuidanceDestination?
    var body: some View {
        Group {
            if let record = store.record(recordID), let plant = store.plant(record.plantID) {
                List {
                    Section {
                        Label(record.kind == .check ? "Check saved" : record.kind == .change ? "Change saved" : "Follow-up saved", systemImage: "checkmark.circle.fill")
                            .font(BloomType.title).foregroundStyle(BloomTheme.teal).accessibilityIdentifier("saved-title")
                        BloomPlantIdentity(plant: plant)
                        Text(record.kind == .check ? record.summary : record.title).font(BloomType.section)
                        if !record.note.isEmpty { Text(record.note).foregroundStyle(.secondary) }
                    }
                    if record.kind == .change {
                        Section { CareGuidanceEntry(observationID: recordID, open: {
                            if let nextSteps { nextSteps() } else { guidance = CareGuidanceDestination(id: recordID) }
                        }) }
                    }
                    else { Section("Next time") { ReminderCard(plantID: plant.id, kind: record.kind == .check ? .soilCheck : .observation, observationID: record.kind == .check ? nil : record.parentID ?? record.id) } }
                    Section("Your record") {
                        NavigationLink { RecordDetailView(recordID: recordID) } label: { Text("View activity") }
                        Button("Edit this record", action: edit)
                        Button("Undo", action: undo).accessibilityIdentifier("undo-record")
                        if record.kind != .check { NavigationLink { SupportView(recordID: recordID) } label: { Text("Get support") } }
                    }
                }.listStyle(.insetGrouped).bloomNativeForm().navigationTitle("Saved").navigationBarTitleDisplayMode(.inline).navigationBarBackButtonHidden()
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done", action: finish).fontWeight(.semibold).accessibilityIdentifier("finish-record") } }
            }
        }
        .fullScreenCover(item: $guidance) { destination in CareGuidanceFlow(observationID: destination.id).id(destination.id) }
    }
}

struct ReminderCard: View {
    @Environment(BloomStore.self) private var store
    let plantID: UUID
    var kind: PlantReminderKind = .soilCheck
    var observationID: UUID? = nil
    var compact = false
    @State private var busy = false
    @State private var message: String?
    @State private var editingDate = false
    private var effectiveKind: PlantReminderKind { store.plant(plantID)?.reminderKind ?? kind }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !compact { Label(effectiveKind == .soilCheck ? "Check soil again" : "Compare your observation", systemImage: effectiveKind == .soilCheck ? "drop" : "eye").font(BloomType.section) }
            if let date = store.plant(plantID)?.reminder { Text(date.formatted(date: .abbreviated, time: .shortened)).font(BloomType.body).foregroundStyle(.secondary) }
            else if !compact { Text("Choose when you'd like to check in again.").font(BloomType.body).foregroundStyle(.secondary) }
            Menu {
                Button("In 3 days") { set(3) }
                Button("In a week") { set(7) }
                Button("Choose date and time…") { editingDate = true }
                if store.plant(plantID)?.reminder != nil { Button("Turn off reminder", role: .destructive) { set(nil) } }
            } label: { BloomActionRow(title: store.plant(plantID)?.reminder == nil ? "Remind me" : "Change reminder") }
                .buttonStyle(.borderless).frame(minHeight: 44, alignment: .leading)
                .disabled(busy).accessibilityIdentifier("reminder-options")
            if !compact { Text("Saved in Care → Tasks. Alerts follow your notification preferences.").font(BloomType.supporting).foregroundStyle(.secondary) }
            if busy { ProgressView().controlSize(.small) }
            if let problem = message ?? store.notificationMessage { Text(problem).font(BloomType.supporting).foregroundStyle(.secondary) }
        }.padding(.vertical, 5)
            .sheet(isPresented: $editingDate) { ReminderEditorView(plantID: plantID, kind: effectiveKind, observationID: observationID) }
    }
    private func set(_ days: Int?) { busy = true; Task { message = await store.setReminder(for: plantID, days: days, kind: effectiveKind, observationID: observationID); busy = false } }
}

struct ReminderEditorView: View {
    @Environment(BloomStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let plantID: UUID
    let kind: PlantReminderKind
    var observationID: UUID? = nil
    @State private var date = Date().addingTimeInterval(259200)
    @State private var busy = false
    @State private var message: String?
    var body: some View {
        NavigationStack {
            Form {
                Section { Text(store.plant(plantID)?.name ?? "Your plant").font(BloomType.section) }
                Section("Next check") { DatePicker("Remind me", selection: $date, in: Date()..., displayedComponents: [.date, .hourAndMinute]).datePickerStyle(.graphical) }
                Section { Text("This saves a task even when notifications are off. New reminders use the time in Preferences; existing dates stay as you chose them.").foregroundStyle(.secondary) }
                if let message { Section { Text(message).foregroundStyle(.red) } }
            }.bloomNativeForm().navigationTitle("Set reminder").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { busy = true; Task { message = await store.setReminder(for: plantID, date: date, kind: kind, observationID: observationID); busy = false; if message == nil { dismiss() } } }.disabled(busy)
                    }
                }
        }.onAppear { date = store.plant(plantID)?.reminder.flatMap { $0 > Date() ? $0 : nil } ?? store.newReminderDate() }
    }
}

struct PlantReminderTaskView: View {
    @Environment(BloomStore.self) private var store
    let plantID: UUID
    @State private var kind: PlantReminderKind?
    @State private var concernID: UUID?
    var body: some View {
        Group {
            if let kind {
                if kind == .observation {
                    if let concernID, let concern = store.record(concernID) { FollowUpView(original: concern) }
                    else { ObservationFlowView(plantID: plantID) }
                } else { CareCheckView(plantID: plantID) }
            } else { ProgressView() }
        }.onAppear {
            guard kind == nil else { return }
            concernID = store.plant(plantID)?.reminderObservationID ?? store.records(for: plantID).first(where: { $0.kind == .change })?.id
            kind = store.plant(plantID)?.reminderKind ?? .soilCheck
        }
    }
}

enum HistoryFilter: String, CaseIterable, Identifiable {
    case all = "All", checks = "Checks", changes = "Changes", followUps = "Follow-ups", actions = "Actions"
    var id: String { rawValue }
}

struct BloomHistoryFilters: View {
    @Binding var filter: HistoryFilter
    var body: some View {
        Picker("Activity type", selection: $filter) { ForEach(HistoryFilter.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.menu)
    }
}

struct HistoryView: View {
    @Environment(BloomStore.self) private var store
    var initialPlantID: UUID? = nil
    @State private var filter = HistoryFilter.all
    @State private var plantID: UUID?
    @State private var showingAll = false
    @State private var initialized = false
    @State private var query = ""
    private var records: [CareRecord] {
        store.garden.records.filter { record in
            (plantID == nil || plantID == record.plantID) &&
            (filter == .all || filter == .checks && record.kind == .check || filter == .changes && record.kind == .change || filter == .followUps && record.kind == .followUp || filter == .actions && record.kind == .careAction) &&
            (query.isEmpty || [record.title, record.summary, record.note, store.plant(record.plantID)?.name ?? ""].contains { $0.localizedCaseInsensitiveContains(query) })
        }.sorted { $0.date > $1.date }
    }
    var body: some View {
        List {
            Section {
                BloomHistoryFilters(filter: $filter)
                Picker("Plant", selection: $plantID) {
                    Text("All plants").tag(UUID?.none)
                    ForEach(store.garden.plants) { Text($0.name).tag(Optional($0.id)) }
                }
            }
            if records.isEmpty { Section { ContentUnavailableView("No activity yet", systemImage: "clock", description: Text("Your saved checks and observations appear here.")) } }
            else {
                Section(showingAll ? "All activity" : "Recent activity · \(min(5, records.count))") {
                    ForEach(showingAll ? records : Array(records.prefix(5))) { record in
                        NavigationLink { RecordDetailView(recordID: record.id) } label: { RecordRow(record: record, plantName: store.plant(record.plantID)?.name ?? "Plant") }
                            .accessibilityIdentifier("history-activity-\(record.id.uuidString)")
                    }
                    if !showingAll && records.count > 5 { Button("Show all activity") { showingAll = true } }
                }
            }
            if store.garden.isSample { Section { Text("Sample activity").font(BloomType.supporting).foregroundStyle(.secondary) } }
        }.listStyle(.insetGrouped).bloomNativeForm().navigationTitle(initialPlantID == nil ? "All activity" : "Plant activity").navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search activity")
            .onAppear { guard !initialized else { return }; initialized = true; plantID = initialPlantID }
    }
}

struct RecordDetailView: View {
    @Environment(BloomStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let recordID: UUID
    @State private var editing = false
    @State private var guidance: CareGuidanceDestination?
    @State private var deleting = false
    @State private var followingUp = false
    private func shareText(_ record: CareRecord, _ plant: Plant) -> String {
        "Bloom · \(plant.name)\n\(record.date.formatted())\n\(record.title)\n\(record.summary)\n\(record.note)\nLocation: \(plant.location)"
    }
    var body: some View {
        Group {
            if let record = store.record(recordID), let plant = store.plant(record.plantID) {
                List {
                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            BloomPlantIdentity(plant: plant)
                            Text(record.title).font(BloomType.section)
                            Text(record.date, format: .dateTime.month().day().year().hour().minute()).font(BloomType.supporting).foregroundStyle(.secondary)
                            if record.kind == .careAction, record.outcome == "Done" || record.outcome == "Skipped" {
                                StatusTag(text: record.outcome == "Done" ? "Action completed" : "Action skipped",
                                          symbol: record.outcome == "Done" ? "checkmark.circle" : "forward",
                                          tone: record.outcome == "Done" ? .teal : .yellow)
                                    .accessibilityIdentifier("record-action-status")
                                if let action = record.action { Text(action.rawValue).font(BloomType.body) }
                            } else { Text(record.summary).font(BloomType.body) }
                            if !record.note.isEmpty { Text(record.note).font(BloomType.body) }
                        }.padding(.vertical, 2)
                        if let data = record.photo, let image = UIImage(data: data) { Image(uiImage: image).resizable().scaledToFit().accessibilityLabel("Saved observation photo") }
                    }
                    if record.kind == .change {
                        Section { CareGuidanceEntry(observationID: recordID, open: { guidance = CareGuidanceDestination(id: recordID) }) }
                        Section("Keep following this observation") {
                            if store.plan(for: recordID) == nil { Button("Compare with a new observation") { followingUp = true } }
                            NavigationLink { SupportView(recordID: recordID) } label: { Text("Get support") }
                            ForEach(store.garden.records.filter { $0.parentID == record.id }.sorted { $0.date > $1.date }) { item in
                                NavigationLink { RecordDetailView(recordID: item.id) } label: { RecordRow(record: item, plantName: plant.name) }
                            }
                        }
                    }
                    if record.parentID.flatMap({ store.record($0) }) != nil || record.planID != nil {
                        Section {
                            if let parent = record.parentID, store.record(parent) != nil {
                                NavigationLink { RecordDetailView(recordID: parent) } label: { Text("Original observation") }
                                    .foregroundStyle(BloomTheme.teal)
                            }
                            if let planID = record.planID {
                                NavigationLink { CarePlanDetailView(planID: planID) } label: { Text("View care plan") }
                                    .foregroundStyle(BloomTheme.teal)
                            }
                        }
                    }
                    if record.planID == nil && record.kind != .change {
                        Section("Next check") { ReminderCard(plantID: plant.id, kind: record.kind == .check ? .soilCheck : .observation, observationID: record.kind == .check ? nil : record.parentID ?? record.id) }
                    }
                    Section {
                        Button(record.planID == nil ? "Edit record" : "Edit note") { editing = true }
                        ShareLink(item: shareText(record, plant)) { Text("Share record") }
                        if record.planTaskID == nil { Button("Delete record", role: .destructive) { deleting = true } }
                    }
                }.listStyle(.insetGrouped).bloomNativeForm().listSectionSpacing(16)
                    .contentMargins(.top, 12, for: .scrollContent).navigationTitle("Your record").navigationBarTitleDisplayMode(.inline)
                    .sheet(isPresented: $editing) {
                        if record.planID != nil { PlanRecordNoteEditor(recordID: recordID) }
                        else if record.kind == .check { CareCheckView(plantID: record.plantID, original: record) }
                        else if record.kind == .change { ObservationFlowView(plantID: record.plantID, original: record) }
                        else { FollowUpView(original: store.record(record.parentID ?? UUID()), editing: record) }
                    }
                    .sheet(isPresented: $followingUp) { FollowUpView(original: record) }
                    .confirmationDialog("Delete this record?", isPresented: $deleting, titleVisibility: .visible) {
                        Button("Delete record", role: .destructive) { if store.deleteRecord(recordID) { dismiss() } }
                    } message: { Text("Linked follow-ups, care plans, and their tasks are also removed.") }
            } else { ContentUnavailableView("Record removed", systemImage: "clock") }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { CareFeedbackBanner(plantID: store.record(recordID)?.plantID) }
        .fullScreenCover(item: $guidance) { destination in CareGuidanceFlow(observationID: destination.id).id(destination.id) }
    }
}

struct FollowUpView: View {
    @Environment(BloomStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let original: CareRecord?
    var editing: CareRecord? = nil
    @State private var outcome = ""
    @State private var note = ""
    @State private var savedID: UUID?
    @State private var receipt: CareSaveReceipt?
    @State private var workingID: UUID?
    @State private var busy = false
    var body: some View {
        NavigationStack {
            if let savedID {
                SavedRecordView(recordID: savedID, edit: { self.savedID = nil }, undo: {
                    Task {
                        let success: Bool
                        if let receipt { success = await store.undoCare(receipt) }
                        else { success = editing.map { store.saveRecord($0) } ?? store.deleteRecord(savedID) }
                        if success { dismiss() }
                    }
                }, finish: { dismiss() })
            } else {
                Form {
                    if let original { Section("Earlier observation") { Text(original.title).font(BloomType.section); Text(original.date, format: .dateTime.month().day()).foregroundStyle(.secondary) } }
                    Section("What do you notice now?") {
                        Picker("Observation", selection: $outcome) {
                            Text("Choose an observation").tag("")
                            ForEach(["Looks better", "About the same", "Looks worse", "Something different", "Not sure"], id: \.self) { Text($0) }
                        }.pickerStyle(.inline)
                    }
                    Section("Notes · Optional") { TextField("What changed?", text: $note, axis: .vertical).lineLimit(3...6) }
                }.bloomNativeForm().navigationTitle("Check in again").navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
                    .bloomNativeFooter {
                        BloomPrimaryAction(title: busy ? "Saving…" : "Save follow-up", action: save).disabled(outcome.isEmpty || busy)
                    }
            }
        }.onAppear { if workingID == nil { outcome = editing?.outcome ?? ""; note = editing?.note ?? "" } }
    }
    private func save() {
        guard let plantID = editing?.plantID ?? original?.plantID else { return }
        var record = editing ?? workingID.flatMap { store.record($0) } ?? CareRecord(plantID: plantID, kind: .followUp, observation: original?.observation ?? "", parentID: original?.id)
        record.outcome = outcome; record.note = note; busy = true
        Task {
            if editing != nil || receipt != nil {
                if store.saveRecord(record) { workingID = record.id; savedID = record.id; BloomFeedback.success() }
            } else if let result = await store.finishCare(record) { receipt = result; workingID = record.id; savedID = record.id; BloomFeedback.success() }
            busy = false
        }
    }
}
