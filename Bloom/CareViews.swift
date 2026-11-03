import SwiftUI
import UserNotifications

struct CareCheckView: View {
    @Environment(BloomStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let plantID: UUID
    var original: CareRecord? = nil
    @State private var draft: CareRecord?
    @State private var busy = false
    @State private var saveError: String?
    private var soil: Binding<Soil?> { Binding(get: { draft?.soil }, set: { draft?.soil = $0 }) }
    private var action: Binding<CareAction?> { Binding(get: { draft?.action }, set: { draft?.action = $0 }) }
    var body: some View {
        NavigationStack {
            Group {
                if let plant = store.plant(plantID) {
                    BloomContentPage {
                        BloomPlantIdentity(plant: plant)
                        Text("How does the soil feel?").bloomHeading()
                        BloomChoiceList(values: Soil.allCases, selection: soil, title: { $0.rawValue }, identifier: { "soil-choice-\($0.rawValue)" })
                        Text("What did you do?").bloomHeading()
                        BloomChoiceList(values: CareAction.allCases, selection: action, title: { $0.rawValue }, identifier: { "care-decision-\($0.rawValue)" })
                        Text("Waiting counts as care, too.").font(BloomType.supporting).foregroundStyle(BloomTheme.secondary)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes · Optional").font(BloomType.supporting).foregroundStyle(BloomTheme.secondary)
                            TextField("Anything to remember?", text: Binding(get: { draft?.note ?? "" }, set: { draft?.note = $0 }), axis: .vertical)
                                .lineLimit(2...4).bloomInput().accessibilityIdentifier("check-note")
                        }
                    }.navigationTitle("Check soil").navigationBarTitleDisplayMode(.inline)
                        .bloomNativeFooter {
                            VStack(spacing: 8) {
                                if draft?.soil == nil || draft?.action == nil {
                                    Text("Choose what you noticed and what you did.")
                                        .font(BloomType.supporting).foregroundStyle(BloomTheme.secondary)
                                        .multilineTextAlignment(.center).frame(maxWidth: .infinity)
                                        .accessibilityIdentifier("check-selection-hint")
                                }
                                if let saveError {
                                    Text(saveError).font(BloomType.supporting).foregroundStyle(.red)
                                }
                                BloomPrimaryAction(title: busy ? "Saving…" : "Save check", action: save)
                                    .disabled(draft?.soil == nil || draft?.action == nil || busy)
                                    .accessibilityIdentifier("save-check")
                            }
                        }
                } else { ContentUnavailableView("Plant unavailable", systemImage: "leaf") }
            }.toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") { dismiss() }.labelStyle(.iconOnly)
                }
            }
        }.onAppear { if draft == nil { draft = original ?? CareRecord(plantID: plantID, kind: .check) } }
    }
    private func save() {
        guard let draft else { return }; busy = true
        Task {
            saveError = nil
            let receipt: CareSaveReceipt?
            if let original, let previousPlant = store.plant(plantID) {
                receipt = store.saveRecord(draft)
                    ? CareSaveReceipt(recordID: draft.id, previousRecord: original, previousPlant: previousPlant, completedReminder: false)
                    : nil
            } else {
                receipt = await store.finishCare(draft)
            }
            if let receipt {
                store.careFeedback = CareFlowFeedback(plantID: plantID, title: original == nil ? "Check saved" : "Check updated",
                    detail: draft.summary, careReceipt: receipt)
                BloomFeedback.success(); dismiss()
            } else { saveError = "Your check couldn't be saved. Please try again." }
            busy = false
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
                BloomContentPage {
                    Label(record.kind == .check ? "Check saved" : record.kind == .change ? "Change saved" : "Follow-up saved", systemImage: "checkmark.circle.fill")
                        .font(BloomType.section).foregroundStyle(BloomTheme.teal).accessibilityIdentifier("saved-title")
                    BloomPlantIdentity(plant: plant)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(record.kind == .check ? record.summary : record.title).font(BloomType.section)
                        if !record.note.isEmpty { Text(record.note).font(BloomType.body).foregroundStyle(BloomTheme.secondary) }
                    }.bloomCard(padding: 16)
                    Text("Next time").bloomHeading()
                    VStack(spacing: 0) {
                        if record.kind == .change {
                            CareGuidanceEntry(observationID: recordID, open: {
                                if let nextSteps { nextSteps() } else { guidance = CareGuidanceDestination(id: recordID) }
                            }).padding(16)
                        } else {
                            ReminderCard(plantID: plant.id, kind: record.kind == .check ? .soilCheck : .observation,
                                         observationID: record.kind == .check ? nil : record.parentID ?? record.id).padding(16)
                        }
                        Divider().padding(.leading, 16)
                        NavigationLink { RecordDetailView(recordID: recordID) } label: { BloomActionRow(title: "View activity") }.padding(16)
                        Divider().padding(.leading, 16)
                        Button(action: edit) { BloomActionRow(title: "Edit this record") }.padding(16)
                        Divider().padding(.leading, 16)
                        Button(action: undo) { BloomActionRow(title: "Undo") }.padding(16).accessibilityIdentifier("undo-record")
                    }.buttonStyle(.plain).background(BloomTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                }.navigationLinkIndicatorVisibility(.hidden).navigationTitle("Saved").navigationBarTitleDisplayMode(.inline).navigationBarBackButtonHidden()
                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Back to plant", systemImage: "chevron.backward", action: finish).labelStyle(.iconOnly) } }
                    .bloomNativeFooter { BloomPrimaryAction(title: "Close record", action: finish).accessibilityIdentifier("finish-record") }

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
    @State private var editingDate = false
    private var effectiveKind: PlantReminderKind { store.plant(plantID)?.reminderKind ?? kind }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !compact { Label(effectiveKind == .soilCheck ? "Check soil again" : "Compare your observation", systemImage: effectiveKind == .soilCheck ? "drop" : "eye").font(BloomType.section) }
            Button { editingDate = true } label: {
                BloomActionRow(title: store.plant(plantID)?.reminder == nil ? "Set reminder" : "Edit reminder")
            }.buttonStyle(.plain)
                .accessibilityIdentifier("reminder-options")
            if let date = store.plant(plantID)?.reminder {
                BloomDatedStatusRow(title: "Next reminder", value: date.formatted(date: .abbreviated, time: .shortened),
                                    accessibilityValue: date.formatted(date: .complete, time: .shortened))
            }
            if let problem = store.notificationMessage { Text(problem).font(BloomType.supporting).foregroundStyle(.secondary) }
        }.padding(.vertical, 5)
            .fullScreenCover(isPresented: $editingDate) { ReminderEditorView(plantID: plantID, kind: effectiveKind, observationID: observationID) }
    }

}

struct ReminderEditorView: View {
    @Environment(BloomStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let plantID: UUID
    let kind: PlantReminderKind
    var observationID: UUID? = nil
    @State private var selectedKind = PlantReminderKind.soilCheck
    @State private var date = Date().addingTimeInterval(259200)
    @State private var selectedPresetDays: Int?
    @State private var busy = false
    @State private var message: String?
    private var concernID: UUID? { observationID ?? store.plant(plantID)?.reminderObservationID ?? store.records(for: plantID).first { $0.kind == .change }?.id }
    private var reminderDate: Binding<Date> {
        Binding(get: { date }, set: { date = $0; selectedPresetDays = nil })
    }
    var body: some View {
        NavigationStack {
            BloomContentPage {
                if let plant = store.plant(plantID) { BloomPlantIdentity(plant: plant) }
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Remind about").font(BloomType.section).foregroundStyle(BloomTheme.ink)
                        Picker("Remind about", selection: $selectedKind) {
                            Text("Check soil").tag(PlantReminderKind.soilCheck)
                            Text("Compare change").tag(PlantReminderKind.observation)
                        }.pickerStyle(.segmented).accessibilityIdentifier("reminder-kind")
                    }
                    Divider()
                    Text("When").font(BloomType.section).foregroundStyle(BloomTheme.ink)
                    DatePicker("Date and time", selection: reminderDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                        .accessibilityIdentifier("reminder-date")
                    HStack(spacing: 10) {
                        presetButton(days: 3, title: "3 days")
                        presetButton(days: 7, title: "1 week")
                    }.frame(maxWidth: .infinity, alignment: .center)
                    if store.plant(plantID)?.reminder != nil {
                        Divider().padding(.top, 2)
                        Button("Turn off", role: .destructive) {
                            busy = true
                            Task { message = await store.setReminder(for: plantID, date: nil); busy = false; if message == nil { dismiss() } }
                        }.font(BloomType.body.weight(.medium))
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .contentShape(Rectangle()).disabled(busy)
                            .accessibilityLabel("Turn off reminder")
                    }
                }.bloomCard(padding: 16)
                if let message { Text(message).font(BloomType.supporting).foregroundStyle(.red) }
            }.navigationTitle("Reminder").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel", systemImage: "xmark") { dismiss() }.labelStyle(.iconOnly) } }
                .bloomNativeFooter {
                    BloomPrimaryAction(title: busy ? "Saving…" : "Save") {
                        if selectedKind == .observation && concernID == nil { message = "Record an observation before adding a comparison reminder."; return }
                        busy = true
                        Task {
                            message = await store.setReminder(for: plantID, date: date, kind: selectedKind, observationID: concernID)
                            busy = false; if message == nil { dismiss() }
                        }
                    }.disabled(busy).accessibilityIdentifier("save-reminder")
                }
        }.onAppear {
            selectedKind = kind
            date = store.plant(plantID)?.reminder.flatMap { $0 > Date() ? $0 : nil } ?? store.newReminderDate()
            selectedPresetDays = nil
        }
    }
    private func presetButton(days: Int, title: String) -> some View {
        let selected = selectedPresetDays == days
        return Button {
            date = store.newReminderDate(days: days)
            selectedPresetDays = days
            BloomFeedback.selection()
        } label: {
            Text(title).font(BloomType.supporting.weight(.semibold))
                .foregroundStyle(selected ? BloomTheme.ink : BloomTheme.teal)
                .frame(minWidth: 76, minHeight: 44)
                .padding(.horizontal, 10)
                .background(selected ? BloomTheme.selected : BloomTheme.surface, in: Capsule())
                .overlay(Capsule().strokeBorder(selected ? BloomTheme.teal : BloomTheme.border, lineWidth: selected ? 1.5 : 1))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(days == 3 ? "reminder-three-days" : "reminder-one-week")
        .accessibilityAddTraits(selected ? .isSelected : [])
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
    @State private var initialized = false
    @State private var query = ""
    private var records: [CareRecord] {
        store.garden.records.filter { record in
            (plantID == nil || plantID == record.plantID) &&
            (filter == .all || filter == .checks && record.kind == .check || filter == .changes && record.kind == .change || filter == .followUps && record.kind == .followUp || filter == .actions && record.kind == .careAction) &&
            (query.isEmpty || [record.title, record.summary, record.note, store.plant(record.plantID)?.displayName ?? ""].contains { $0.localizedCaseInsensitiveContains(query) })
        }.sorted { $0.date > $1.date }
    }
    var body: some View {
        List {
            Section {
                BloomHistoryFilters(filter: $filter)
                Picker("Plant", selection: $plantID) {
                    Text("All plants").tag(UUID?.none)
                    ForEach(store.garden.plants) { Text($0.displayName).tag(Optional($0.id)) }
                }
            }
            if records.isEmpty { Section { ContentUnavailableView("No activity yet", systemImage: "clock") } }
            else {
                Section("All activity") {
                    ForEach(records) { record in
                        NavigationLink { RecordDetailView(recordID: record.id) } label: {
                            HStack(spacing: 10) {
                                RecordRow(record: record, plantName: store.plant(record.plantID)?.displayName ?? "Plant")
                                BloomSymbol(name: "chevron.right", compact: true).foregroundStyle(BloomTheme.teal)
                            }
                        }
                            .accessibilityIdentifier("history-activity-\(record.id.uuidString)")
                    }
                }
            }
            if store.garden.isSample { Section { Text("Sample activity").font(BloomType.supporting).foregroundStyle(.secondary) } }
        }.listStyle(.insetGrouped).bloomNativeForm().navigationLinkIndicatorVisibility(.hidden)
            .navigationTitle(initialPlantID == nil ? "All activity" : "Plant activity").navigationBarTitleDisplayMode(.inline)
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
        "Bloom · \(plant.displayName)\n\(record.date.formatted())\n\(record.title)\n\(record.summary)\n\(record.note)\nLocation: \(plant.location)"
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
                            NavigationLink { SupportView(recordID: recordID) } label: { BloomActionRow(title: "Get support") }
                            ForEach(store.garden.records.filter { $0.parentID == record.id }.sorted { $0.date > $1.date }) { item in
                                NavigationLink { RecordDetailView(recordID: item.id) } label: {
                                    HStack(spacing: 10) {
                                        RecordRow(record: item, plantName: plant.displayName)
                                        BloomSymbol(name: "chevron.right", compact: true).foregroundStyle(BloomTheme.teal)
                                    }
                                }
                            }
                        }
                    }
                    if record.parentID.flatMap({ store.record($0) }) != nil || record.planID != nil {
                        Section {
                            if let parent = record.parentID, store.record(parent) != nil {
                                NavigationLink { RecordDetailView(recordID: parent) } label: { BloomActionRow(title: "Original observation") }
                            }
                            if let planID = record.planID {
                                NavigationLink { CarePlanDetailView(planID: planID) } label: { BloomActionRow(title: "View care plan") }
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
                }.listStyle(.insetGrouped).bloomNativeForm().navigationLinkIndicatorVisibility(.hidden).listSectionSpacing(16)
                    .contentMargins(.top, 12, for: .scrollContent).navigationTitle("Your record").navigationBarTitleDisplayMode(.inline)
                    .fullScreenCover(isPresented: $editing) {
                        if record.planID != nil { PlanRecordNoteEditor(recordID: recordID) }
                        else if record.kind == .check { CareCheckView(plantID: record.plantID, original: record) }
                        else if record.kind == .change { ObservationFlowView(plantID: record.plantID, original: record) }
                        else { FollowUpView(original: store.record(record.parentID ?? UUID()), editing: record) }
                    }
                    .fullScreenCover(isPresented: $followingUp) { FollowUpView(original: record) }
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
                        BloomChoiceList(values: ["Looks better", "About the same", "Looks worse", "Something different", "Not sure"],
                                        selection: Binding(get: { outcome.isEmpty ? nil : outcome }, set: { outcome = $0 ?? "" }), title: { $0 })
                            .listRowInsets(EdgeInsets())
                    }
                    Section("Notes · Optional") { TextField("What changed?", text: $note, axis: .vertical).lineLimit(3...6) }
                }.bloomNativeForm().navigationTitle("Check in again").navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel", systemImage: "xmark") { dismiss() }.labelStyle(.iconOnly) } }
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
