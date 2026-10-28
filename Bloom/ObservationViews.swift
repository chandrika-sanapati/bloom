import SwiftUI
import PhotosUI

private enum ObservationPage: Hashable { case symptoms, context }

struct ObservationFlowView: View {
    @Environment(BloomStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
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
    @State private var saveError: String?
    var body: some View {
        Group {
            if let savedID {
                CareGuidanceFlow(observationID: savedID, justSaved: true, returnLabel: original == nil ? "Back to plant" : "Back to record", finish: finishObservation)
            } else { editor }
        }
    }
    private var editor: some View {
        NavigationStack(path: $path) {
            Group {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            if let plant = store.plant(plantID) { BloomPlantIdentity(plant: plant) }
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Where do you notice it?").bloomHeading()
                                Text("Choose the part of your plant. If you're unsure, choose Whole plant.").font(BloomType.body).foregroundStyle(.secondary)
                            }
                            LazyVGrid(columns: cardColumns, spacing: 12) {
                                ForEach(PlantArea.allCases) { item in
                                    Button {
                                        if area != item { observation = ""; customObservation = "" }
                                        area = item; path.append(.symptoms); BloomFeedback.selection()
                                    } label: {
                                        VStack(alignment: .leading, spacing: 0) {
                                            PlantAreaArtwork(area: item).frame(height: 76).accessibilityHidden(true)
                                            VStack(alignment: .leading, spacing: 5) {
                                                HStack(alignment: .firstTextBaseline) {
                                                    Text(item.rawValue).font(BloomType.section)
                                                    Spacer(minLength: 2)
                                                    BloomSymbol(name: area == item ? "checkmark.circle.fill" : "chevron.right")
                                                        .foregroundStyle(BloomTheme.teal).accessibilityHidden(true)
                                                }
                                                Text(item.subtitle).font(BloomType.supporting).foregroundStyle(.secondary)
                                            }.padding(12).frame(maxWidth: .infinity, alignment: .leading)
                                        }.background(area == item ? BloomTheme.selected : BloomTheme.surface)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(area == item ? BloomTheme.teal : BloomTheme.border, lineWidth: area == item ? 2 : 1))
                                    }.buttonStyle(BloomPressStyle()).foregroundStyle(BloomTheme.ink)
                                        .accessibilityIdentifier("observation-area-\(item)")
                                        .accessibilityLabel(item.rawValue).accessibilityHint("Choose this area and see changes")
                                        .accessibilityAddTraits(area == item ? .isSelected : [])
                                }
                            }
                        }.padding(20).frame(maxWidth: 620).frame(maxWidth: .infinity)
                    }.background(BloomTheme.canvas).navigationTitle("Notice a change").navigationBarTitleDisplayMode(.inline)
            }.toolbar { if savedID == nil { ToolbarItem(placement: .cancellationAction) { Button("Cancel", systemImage: "xmark") { dismiss() }.labelStyle(.iconOnly) } } }
                .navigationDestination(for: ObservationPage.self) { page in
                    if page == .symptoms { symptomCards }
                    else { contextPage }

                }
        }.onAppear {
            guard !initialized else { return }; initialized = true
            area = original?.area ?? initialArea; observation = original?.observation ?? ""
            firstNoticed = original?.firstNoticed ?? "Not sure"; wateringContext = original?.wateringContext ?? "I don't know"
            lightChanged = original?.lightChanged ?? "Not sure"; note = original?.note ?? ""; photoData = original?.photo
            if let original, !(area?.observations.contains(original.observation) ?? false) { customObservation = original.observation; observation = "Something else" }
            if original != nil { path = [.context] }
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
    private var contextPage: some View {
        BloomContentPage {
            Text(observation == "Something else" ? customObservation : observation).font(BloomType.section).bloomCard(padding: 16)
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes · Optional").font(BloomType.supporting).foregroundStyle(BloomTheme.secondary)
                TextField("Add a note", text: $note, axis: .vertical).lineLimit(3...6).bloomInput().accessibilityIdentifier("observation-note")
            }
            DisclosureGroup("Add care details") {
                VStack(spacing: 14) {
                    Picker("First noticed", selection: $firstNoticed) { ForEach(["Not sure", "Recently", "A while ago"], id: \.self) { Text($0) } }
                    Picker("Last watered", selection: $wateringContext) { ForEach(["I don't know", "Today", "Within a week", "More than a week ago"], id: \.self) { Text($0) } }
                    Picker("Light or location changed?", selection: $lightChanged) { ForEach(["Not sure", "Yes", "No"], id: \.self) { Text($0) } }
                }.padding(.top, 12)
            }
            Text("Photo · Optional").bloomHeading()
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Text(photoLoading ? "Opening photo…" : "Add a photo").frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }.buttonStyle(.bordered).disabled(photoLoading)
            if let photoData, let image = UIImage(data: photoData) {
                Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 200)
                Button("Remove photo", role: .destructive) { self.photoData = nil; selectedPhoto = nil }
            }
            if let photoError { Text(photoError).font(BloomType.supporting).foregroundStyle(.red) }
            if let saveError { Text(saveError).foregroundStyle(.red) }
        }.navigationTitle("Photo and note").navigationBarTitleDisplayMode(.inline)
            .bloomNativeFooter {
                BloomPrimaryAction(title: busy ? "Saving…" : "Save change", action: save)
                    .disabled(!validObservation || photoLoading || busy).accessibilityIdentifier("save-change")
            }
    }
    private var cardColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), alignment: .top), count: dynamicTypeSize.isAccessibilitySize ? 1 : 2)
    }
    private var symptomCards: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let area {
                    HStack(spacing: 12) {
                        PlantAreaArtwork(area: area).frame(width: 56, height: 56).clipShape(RoundedRectangle(cornerRadius: 12)).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(area.rawValue).font(BloomType.section)
                            Text("Describe what you see. You don't need to know the cause.").font(BloomType.body).foregroundStyle(.secondary)
                        }
                    }
                    LazyVGrid(columns: cardColumns, spacing: 12) {
                        ForEach(area.observations, id: \.self) { value in
                            Button { observation = value; BloomFeedback.selection() } label: {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        BloomSymbol(name: observationSymbol(value)).foregroundStyle(BloomTheme.teal)
                                        Spacer(minLength: 4)
                                        BloomSymbol(name: observation == value ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(observation == value ? BloomTheme.teal : BloomTheme.secondary)
                                    }.accessibilityHidden(true)
                                    Text(value).font(BloomType.section).fixedSize(horizontal: false, vertical: true)
                                }.frame(maxWidth: .infinity, minHeight: 78, alignment: .topLeading).padding(16)
                                    .background(observation == value ? BloomTheme.selected : BloomTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(observation == value ? BloomTheme.teal : BloomTheme.border, lineWidth: observation == value ? 2 : 1))
                                    .contentShape(RoundedRectangle(cornerRadius: 16))
                            }.buttonStyle(BloomPressStyle()).foregroundStyle(BloomTheme.ink)
                                .accessibilityLabel(value).accessibilityIdentifier("observation-change-\(value)")
                                .accessibilityAddTraits(observation == value ? .isSelected : [])
                        }
                    }
                    if observation == "Something else" {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What looks different?").bloomHeading()
                            TextField("Describe the change", text: $customObservation, axis: .vertical).lineLimit(2...4)
                                .textFieldStyle(.roundedBorder).accessibilityIdentifier("custom-observation")
                        }
                    }
                }
            }.padding(20).frame(maxWidth: 620).frame(maxWidth: .infinity)
        }.background(BloomTheme.canvas).navigationTitle("What looks different?").navigationBarTitleDisplayMode(.inline)
            .bloomNativeFooter {
                VStack(spacing: 8) {
                    if !validObservation {
                        Text(observation == "Something else" ? "Describe the change." : "Choose a change.")
                            .font(BloomType.supporting).foregroundStyle(BloomTheme.secondary)
                            .multilineTextAlignment(.center).frame(maxWidth: .infinity)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("observation-selection-hint")
                    }
                    BloomPrimaryAction(title: "Review change") { path.append(.context) }
                        .disabled(!validObservation).accessibilityIdentifier("continue-observation")
                }
            }
    }
    private func observationSymbol(_ value: String) -> String {
        switch value {
        case "Dropping leaves", "Flowers dropping", "Early fruit drop": "arrow.down"
        case "Yellowing leaves", "Brown edges", "Changed color": "paintpalette"
        case "Spots or patches": "circle.dotted"
        case "Curling or drooping", "Leaning or drooping", "Leaning": "arrow.down.right"
        case "Visible insects", "Webs or eggs": "ant"
        case "No new growth", "Flowers aren't appearing": "leaf"
        case "Soft or mushy": "hand.point.up.left"
        case "Sticky residue": "drop"
        case "Something else": "pencil"
        default: "eye"
        }
    }
    private var validObservation: Bool { area != nil && !observation.isEmpty && (observation != "Something else" || !customObservation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
    private func finishObservation() {
        if let savedID, store.plan(for: savedID) == nil {
            store.careFeedback = CareFlowFeedback(plantID: plantID, title: "Change saved", detail: "You can find guidance again in this plant's activity.")
        }
        dismiss()
    }
    private func showConfirmation(_ id: UUID) {
        workingID = id
        path.removeAll()
        BloomFeedback.success()
        if store.plan(for: id) != nil {
            store.careFeedback = CareFlowFeedback(plantID: plantID, title: "Change updated", detail: "Your existing care plan is unchanged.")
            dismiss()
        } else { savedID = id }
    }
    private func save() {
        var record = original ?? workingID.flatMap { store.record($0) } ?? CareRecord(plantID: plantID, kind: .change)
        record.area = area; record.observation = observation == "Something else" ? customObservation.trimmingCharacters(in: .whitespacesAndNewlines) : observation
        record.firstNoticed = firstNoticed; record.wateringContext = wateringContext; record.lightChanged = lightChanged; record.note = note; record.photo = photoData
        busy = true
        Task {
            var saved = false
            if original != nil || receipt != nil {
                saved = store.saveRecord(record)
            } else if let result = await store.finishCare(record) { receipt = result; saved = true }
            if saved { showConfirmation(record.id) }
            else { saveError = "Your change couldn't be saved. Please try again." }
            busy = false
        }
    }
}

/// Generic area cues avoid presenting another plant's photograph as the user's plant.
struct PlantAreaArtwork: View {
    let area: PlantArea
    private var symbol: String {
        switch area {
        case .whole: "tree"
        case .leaves: "leaf"
        case .stems: "leaf.arrow.triangle.circlepath"
        case .flowers: "camera.macro"
        case .fruits: "carrot"
        case .pests: "ant"
        }
    }
    var body: some View {
        ZStack {
            BloomTheme.selected
            Circle().fill(Color.white.opacity(0.6)).frame(width: 60, height: 60)
            if area == .whole {
                PlantFormArtwork(form: .bushy).frame(width: 64, height: 68)
            } else if area == .stems {
                Canvas { context, size in
                    var stem = Path()
                    stem.move(to: CGPoint(x: 24, y: 46)); stem.addLine(to: CGPoint(x: 24, y: 4))
                    stem.move(to: CGPoint(x: 24, y: 18)); stem.addLine(to: CGPoint(x: 9, y: 8))
                    stem.move(to: CGPoint(x: 24, y: 31)); stem.addLine(to: CGPoint(x: 40, y: 17))
                    context.stroke(stem, with: .color(BloomTheme.teal), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                }.frame(width: 48, height: 48)
            } else if area == .fruits {
                ZStack {
                    Circle().fill(BloomTone.yellow.accent).frame(width: 28, height: 28).offset(x: -9, y: 6)
                    Circle().fill(BloomTone.yellow.accent).frame(width: 26, height: 26).offset(x: 12, y: 9)
                    Image(systemName: "leaf.fill").font(.system(size: 22)).foregroundStyle(BloomTheme.teal).offset(x: 3, y: -12)
                }
            } else {
                Image(systemName: symbol).font(.system(size: 32, weight: .regular))
                    .foregroundStyle(BloomTheme.teal)
            }
        }.frame(maxWidth: .infinity)
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
                    Text(record.observation).font(BloomType.section)
                    Text("A visible change can have more than one explanation. Your record helps you compare what happens next.").foregroundStyle(.secondary)
                }
                Section("What to compare") {
                    Label("Look at the same area under similar light.", systemImage: "sun.max")
                    Label("Compare your saved photo and notes.", systemImage: "photo.on.rectangle")
                    Label("Record what looks the same, better, or different.", systemImage: "square.and.pencil")
                }
                Section("Ask for help") {
                    Text("Bring a whole-plant photo, a close-up, and your recent care notes to a plant-care specialist if you're concerned.")
                    ShareLink(item: "Plant: \(plant.name) (\(plant.species))\nObservation: \(record.observation)\nFirst noticed: \(record.firstNoticed)\nLast watered: \(record.wateringContext)\nLocation/light changed: \(record.lightChanged)\nNotes: \(record.note)") { Text("Share your observation") }
                    NavigationLink { PlantDetailView(plantID: plant.id) } label: { Text("Review plant details") }
                }
                Section("Check in again") { ReminderCard(plantID: plant.id, kind: .observation, observationID: record.kind == .change ? record.id : record.parentID) }
            }
        }.listStyle(.insetGrouped).bloomNativeForm().navigationTitle("Get support").navigationBarTitleDisplayMode(.inline)
    }
}
