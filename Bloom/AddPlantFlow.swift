import SwiftUI
import PhotosUI
import UIKit
import Observation

enum PlantAddStep: Hashable { case review, location, status }
@MainActor @Observable private final class PlantSetupDraft {
    var plant = Plant(name: "", species: "", asset: "")
    var placement = PlantPlacement.indoor
    var status: InitialPlantStatus?
    var photoMessage: String?
    var chosenPhoto: PhotosPickerItem?
    var loading = false
}

struct AddPlantFlowView: View {
    var navigate: (PlantAddStep) -> Void
    var completed: (UUID) -> Void
    @Environment(BloomStore.self) private var store
    @State private var query = ""
    @State private var setup = PlantSetupDraft()

    var body: some View {
        ScrollView {
            PlantDiscoveryView(query: $query, select: select, addCustom: addCustom)
                .padding(.horizontal, 20).padding(.top, 6).padding(.bottom, 24)
        }.background(BloomTheme.canvas).scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .top, spacing: 0) {
                BloomPlantSearchField(query: $query, submitted: { store.rememberPlantSearch(query) })
                    .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 16).background(BloomTheme.canvas)
            }
            .navigationTitle("Add plant").bloomAddPage()
            .navigationDestination(for: PlantAddStep.self) { step in
                switch step {
                case .review: review
                case .location: location
                case .status: currentStatus
                }
            }
    }
    private var review: some View {
        Form {
            Section {
                PlantPortrait(plant: setup.plant, contentMode: .fit).frame(height: 210).listRowInsets(EdgeInsets()).listRowBackground(Color.clear)
                TextField("Plant nickname", text: $setup.plant.name).textInputAutocapitalization(.words).accessibilityIdentifier("overlay-plant-name")
                if !setup.plant.species.isEmpty { LabeledContent("Species", value: setup.plant.species) }
            } header: { Text("Your new plant · 1 of 3") }
            if duplicateCount > 0 {
                Section {
                    Text("You already have \(duplicateCount == 1 ? "this plant" : "\(duplicateCount) of these plants"). Give this one a nickname to tell them apart.")
                        .font(BloomType.body).foregroundStyle(BloomTheme.secondary).accessibilityIdentifier("duplicate-plant-hint")
                }
            }
            Section("Photo · Optional") {
                PhotosPicker(selection: $setup.chosenPhoto, matching: .images) { Text("Choose a photo") }.disabled(setup.loading).accessibilityIdentifier("setup-add-photo")
                if setup.loading { ProgressView("Opening photo…") }
                if let message = setup.photoMessage { Text(message).font(BloomType.supporting).foregroundStyle(.secondary) }
            }
            if let species = PlantSpecies.catalog.first(where: { $0.scientific == setup.plant.species }) {
                Section("A little about it") {
                    LabeledContent("Care", value: species.care.rawValue)
                    Label(species.light.rawValue, systemImage: species.light.symbol)
                }
            }
        }.bloomNativeForm().navigationTitle("Add plant").bloomAddPage()
            .onChange(of: setup.chosenPhoto) { _, item in
                guard let item else { return }; setup.loading = true; setup.photoMessage = nil
                Task {
                    do {
                        guard let data = try await item.loadTransferable(type: Data.self), let image = UIImage(data: data),
                              let compressed = image.preparingThumbnail(of: CGSize(width: 1200, height: 1200))?.jpegData(compressionQuality: 0.8) else { throw CocoaError(.fileReadCorruptFile) }
                        setup.plant.photo = compressed
                    } catch { setup.photoMessage = "This photo couldn't be opened. Please choose another." }
                    setup.loading = false; setup.chosenPhoto = nil
                }
            }
            .bloomNativeFooter {
                BloomPrimaryAction(title: "Continue") { navigate(.location) }
                    .disabled(setup.plant.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || setup.loading).accessibilityIdentifier("overlay-continue-plant")
            }
    }
    private var location: some View {
        Form {
            Section {
                Picker("Placement", selection: $setup.placement) { ForEach(PlantPlacement.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented)
                TextField("Room or location", text: $setup.plant.location).accessibilityIdentifier("setup-custom-location")
                Menu {
                    ForEach(setup.placement == .indoor ? PlantRoom.indoor : PlantRoom.outdoor) { room in
                        Button(room.name) { setup.plant.location = room.name; BloomFeedback.selection() }.accessibilityIdentifier("setup-room-\(room.name)")
                    }
                } label: { Text("Choose a room").frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle()) }.buttonStyle(.borderless).accessibilityIdentifier("setup-room-menu")
            } header: { Text("Location · 2 of 3") }
            Section { BloomPlantIdentity(plant: setup.plant) }
        }.bloomNativeForm().navigationTitle("A place to grow").bloomAddPage()
            .bloomNativeFooter {
                VStack(spacing: 8) {
                    BloomPrimaryAction(title: "Continue") { navigate(.status) }.disabled(setup.plant.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).accessibilityIdentifier("setup-continue-location")
                    Button("Choose later") { setup.plant.location = ""; navigate(.status) }.frame(minHeight: 36)
                }
            }
    }
    private var currentStatus: some View {
        Form {
            Section {
                Picker("Current status", selection: $setup.status) {
                    Text("Choose a status").tag(InitialPlantStatus?.none)
                    ForEach(InitialPlantStatus.allCases) { item in Text(item.rawValue).tag(Optional(item)).accessibilityIdentifier("setup-status-\(item.rawValue)") }
                }.pickerStyle(.inline)
            } header: { Text("A first impression · 3 of 3") }
            Section { BloomPlantIdentity(plant: setup.plant) }
        }.bloomNativeForm().navigationTitle("How is it doing?").bloomAddPage()
            .bloomNativeFooter {
                VStack(spacing: 8) {
                    BloomPrimaryAction(title: "Add plant", action: save).disabled(setup.status == nil).accessibilityIdentifier("overlay-save-plant")
                    Button("Choose later") { setup.status = .notSure; save() }.frame(minHeight: 36)
                }
            }
    }
    private func select(_ species: PlantSpecies) {
        store.rememberPlantSearch(query.isEmpty ? species.name : query)
        setup.plant = Plant(name: species.name, species: species.scientific, asset: species.asset)
        setup.status = nil; setup.placement = .indoor; navigate(.review)
    }
    private func addCustom(_ name: String) { store.rememberPlantSearch(name); setup.plant = Plant(name: name, species: "", asset: ""); setup.status = nil; setup.placement = .indoor; navigate(.review) }
    private func save() {
        setup.plant.location = setup.plant.location.trimmingCharacters(in: .whitespacesAndNewlines)
        if store.addPlant(setup.plant, placement: setup.placement, status: setup.status) {
            store.careFeedback = CareFlowFeedback(plantID: setup.plant.id, title: "\(setup.plant.name) added", detail: "Saved to My plants.")
            BloomFeedback.success(); completed(setup.plant.id)
        }
    }
    private var duplicateCount: Int {
        store.garden.plants.filter {
            !setup.plant.species.isEmpty ? $0.species == setup.plant.species : $0.name.localizedCaseInsensitiveCompare(setup.plant.name) == .orderedSame
        }.count
    }
}

private extension View {
    func bloomAddPage() -> some View {
        navigationBarTitleDisplayMode(.inline).toolbarRole(.editor)
            .toolbar(.visible, for: .navigationBar)
            .toolbar(.hidden, for: .tabBar)
    }
}

