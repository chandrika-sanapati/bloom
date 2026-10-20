import SwiftUI
import PhotosUI

private enum ObservationPage: Hashable { case context }

struct ObservationFlowView: View {
    @Environment(BloomStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let plantID: UUID
    var initialArea: PlantArea? = nil
    var original: CareRecord? = nil
    var embedded = false
    @State private var path: [ObservationPage] = []
    @State private var area: PlantArea?
    @State private var observation = ""
    @State private var customObservation = ""
    @State private var firstNoticed = "Not sure"
    @State private var wateringContext = "I don't know"
    @State private var lightChanged = "Not sure"
    @State private var note = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var photoError: String?
    @State private var photoLoading = false
    @State private var savedID: UUID?
    @State private var workingID: UUID?
    @State private var receipt: CareSaveReceipt?
    @State private var initialized = false
    @State private var busy = false
    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if let savedID { confirmation(savedID) }
                else {
                    Form {
                        if let plant = store.plant(plantID) { Section { BloomPlantIdentity(plant: plant) } }
                        Section {
                            Picker("Area", selection: $area) {
                                Text("Choose an area").tag(PlantArea?.none)
                                ForEach(PlantArea.allCases) { Text($0.rawValue).tag(Optional($0)) }
                            }
                        }
                        if let area {
                            Section {
                                Image(area.asset).resizable().scaledToFit().frame(height: 120).frame(maxWidth: .infinity).accessibilityHidden(true)
                                Picker("Observation", selection: $observation) {
                                    Text("Choose an observation").tag("")
                                    ForEach(area.observations, id: \.self) { Text($0) }
                                }.pickerStyle(.inline)
                                if observation == "Something else" { TextField("Describe the change", text: $customObservation, axis: .vertical) }
                            } header: { Text("What do you notice?") } footer: { Text("Describe what you see. You don't need to know the cause.") }
                        }
                    }.bloomNativeForm().navigationTitle("Notice a change").navigationBarTitleDisplayMode(.inline)
                        .bloomNativeFooter { BloomPrimaryAction(title: "Continue") { path.append(.context) }.disabled(!validObservation).accessibilityIdentifier("continue-observation") }
                }
            }.toolbar { if savedID == nil { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } } }
                .navigationDestination(for: ObservationPage.self) { _ in
                    if let savedID { confirmation(savedID) }
                    else {
                        Form {
                            Section { Text(observation == "Something else" ? customObservation : observation).font(.headline) }
                            Section("A little context · Optional") {
                                Picker("First noticed", selection: $firstNoticed) { ForEach(["Not sure", "Recently", "A while ago"], id: \.self) { Text($0) } }
                                Picker("Last watered", selection: $wateringContext) { ForEach(["I don't know", "Today", "Within a week", "More than a week ago"], id: \.self) { Text($0) } }
                                Picker("Light or location changed?", selection: $lightChanged) { ForEach(["Not sure", "Yes", "No"], id: \.self) { Text($0) } }
                                TextField("Add a note", text: $note, axis: .vertical).lineLimit(3...6)
                            }
                            Section("Photo · Optional") {
                                PhotosPicker(selection: $selectedPhoto, matching: .images) { Label(photoLoading ? "Opening photo…" : "Add a photo", systemImage: "photo") }.disabled(photoLoading)
                                if let photoData, let image = UIImage(data: photoData) {
                                    Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 200)
                                    Button("Remove photo", role: .destructive) { self.photoData = nil; selectedPhoto = nil }
                                }
                                if let photoError { Text(photoError).font(.footnote).foregroundStyle(.red) }
                            }
                        }.bloomNativeForm().navigationTitle("Add context").navigationBarTitleDisplayMode(.inline)
                            .bloomNativeFooter {
                                BloomPrimaryAction(title: busy ? "Saving…" : "Save change", symbol: "checkmark", action: save).disabled(!validObservation || photoLoading || busy).accessibilityIdentifier("save-change")
                            }
                    }
                }
        }.onAppear {
            guard !initialized else { return }; initialized = true
            area = original?.area ?? initialArea; observation = original?.observation ?? ""
            firstNoticed = original?.firstNoticed ?? "Not sure"; wateringContext = original?.wateringContext ?? "I don't know"
            lightChanged = original?.lightChanged ?? "Not sure"; note = original?.note ?? ""; photoData = original?.photo
            if let original, !(area?.observations.contains(original.observation) ?? false) { customObservation = original.observation; observation = "Something else" }
        }.onChange(of: area) { _, next in
            if observation != "Something else", let next, !next.observations.contains(observation) { observation = "" }
        }.onChange(of: selectedPhoto) { _, item in
            guard let item else { return }; photoLoading = true
            Task {
                do {
                    guard let data = try await item.loadTransferable(type: Data.self), let image = UIImage(data: data), let compressed = image.preparingThumbnail(of: CGSize(width: 1200, height: 1200))?.jpegData(compressionQuality: 0.8) else { throw CocoaError(.fileReadCorruptFile) }
                    photoData = compressed; photoError = nil
                } catch { photoError = "This photo couldn't be opened. Please choose another." }
                photoLoading = false
            }
        }
    }
    private var validObservation: Bool { area != nil && !observation.isEmpty && (observation != "Something else" || !customObservation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
    private func confirmation(_ id: UUID) -> some View {
        SavedRecordView(recordID: id, edit: { savedID = nil }, undo: {
            Task {
                let success: Bool
                if let receipt { success = await store.undoCare(receipt) }
                else { success = original.map { store.saveRecord($0) } ?? store.deleteRecord(id) }
                if success { dismiss() }
            }
        }, finish: { dismiss() })
    }
    private func save() {
        var record = original ?? workingID.flatMap { store.record($0) } ?? CareRecord(plantID: plantID, kind: .change)
        record.area = area; record.observation = observation == "Something else" ? customObservation.trimmingCharacters(in: .whitespacesAndNewlines) : observation
        record.firstNoticed = firstNoticed; record.wateringContext = wateringContext; record.lightChanged = lightChanged; record.note = note; record.photo = photoData
        busy = true
        Task {
            if original != nil || receipt != nil {
                if store.saveRecord(record) { workingID = record.id; savedID = record.id; BloomFeedback.success() }
            } else if let result = await store.finishCare(record) { receipt = result; workingID = record.id; savedID = record.id; BloomFeedback.success() }
            busy = false
        }
    }
}

struct SupportView: View {
    @Environment(BloomStore.self) private var store
    let recordID: UUID
    var body: some View {
        List {
            if let record = store.record(recordID), let plant = store.plant(record.plantID) {
                Section {
                    BloomPlantIdentity(plant: plant)
                    Text(record.observation).font(.headline)
                    Text("A visible change can have more than one explanation. Your record helps you compare what happens next.").foregroundStyle(.secondary)
                }
                Section("What to compare") {
                    Label("Look at the same area under similar light.", systemImage: "sun.max")
                    Label("Compare your saved photo and notes.", systemImage: "photo.on.rectangle")
                    Label("Record what looks the same, better, or different.", systemImage: "square.and.pencil")
                }
                Section("Ask for help") {
                    Text("Bring a whole-plant photo, a close-up, and your recent care notes to a plant-care specialist if you're concerned.")
                    ShareLink(item: "Plant: \(plant.name) (\(plant.species))\nObservation: \(record.observation)\nFirst noticed: \(record.firstNoticed)\nLast watered: \(record.wateringContext)\nLocation/light changed: \(record.lightChanged)\nNotes: \(record.note)") { Label("Share your observation", systemImage: "square.and.arrow.up") }
                    NavigationLink { PlantDetailView(plantID: plant.id) } label: { Label("Review plant details", systemImage: "leaf") }
                }
                Section("Check in again") { ReminderCard(plantID: plant.id, kind: .observation, observationID: record.kind == .change ? record.id : record.parentID) }
            }
        }.listStyle(.insetGrouped).bloomNativeForm().navigationTitle("Get support").navigationBarTitleDisplayMode(.inline)
    }
}
