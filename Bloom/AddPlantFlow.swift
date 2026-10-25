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
        BloomContentPage {
            Text("Your new plant · 1 of 3").bloomHeading()
            PlantPortrait(plant: setup.plant, contentMode: .fit).frame(height: 210)
                .background(BloomTheme.surface, in: RoundedRectangle(cornerRadius: 16))
            VStack(alignment: .leading, spacing: 8) {
                Text("Plant nickname").font(BloomType.supporting).foregroundStyle(BloomTheme.secondary)
                TextField("Plant nickname", text: $setup.plant.name).textInputAutocapitalization(.words)
                    .bloomInput().accessibilityIdentifier("overlay-plant-name")
                if !setup.plant.species.isEmpty { LabeledContent("Species", value: setup.plant.species).font(BloomType.body).padding(.vertical, 8) }
            }
            if duplicateCount > 0 {
                Text("You already have this plant. Give this one a nickname to tell them apart.")
                    .font(BloomType.supporting).foregroundStyle(BloomTone.yellow.ink)
                    .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                    .background(BloomTone.yellow.surface, in: RoundedRectangle(cornerRadius: 16))
                    .accessibilityIdentifier("duplicate-plant-hint")
            }
            Text("Photo · Optional").bloomHeading()
            PhotosPicker(selection: $setup.chosenPhoto, matching: .images) {
                Text("Choose a photo").frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }.buttonStyle(.bordered).disabled(setup.loading).accessibilityIdentifier("setup-add-photo")
            if setup.loading { ProgressView("Opening photo…") }
            if let message = setup.photoMessage { Text(message).font(BloomType.supporting).foregroundStyle(.secondary) }
            if let species = PlantSpecies.catalog.first(where: { $0.scientific == setup.plant.species }) {
                Text("A little about it").bloomHeading()
                VStack(spacing: 0) {
                    HStack { Text("Care"); Spacer(); StatusTag(text: "\(species.care.rawValue) care", tone: species.care == .easy ? .teal : .yellow) }.padding(16)
                    Divider().padding(.leading, 16)
                    LabeledContent("Light", value: species.light.rawValue).padding(16)
                }.font(BloomType.body).background(BloomTheme.surface, in: RoundedRectangle(cornerRadius: 16))
            }
        }.navigationTitle("Add plant").bloomAddPage()
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
        BloomContentPage {
            Text("Location · 2 of 3").bloomHeading()
            Picker("Placement", selection: $setup.placement) {
                ForEach(PlantPlacement.allCases) { Text($0.rawValue).tag($0) }
            }.pickerStyle(.segmented).accessibilityIdentifier("setup-placement")
            VStack(alignment: .leading, spacing: 8) {
                Text("Room or location").font(BloomType.supporting).foregroundStyle(BloomTheme.secondary)
                TextField("Room or location", text: $setup.plant.location).bloomInput().accessibilityIdentifier("setup-custom-location")
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 10)], spacing: 10) {
                ForEach(setup.placement == .indoor ? PlantRoom.indoor : PlantRoom.outdoor) { room in
                    let selected = setup.plant.location == room.name
                    Button { setup.plant.location = room.name; BloomFeedback.selection() } label: {
                        Text(room.name).font(BloomType.supporting).foregroundStyle(BloomTheme.teal)
                            .frame(maxWidth: .infinity, minHeight: 44).padding(.horizontal, 10)
                            .background(selected ? BloomTheme.selected : BloomTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(selected ? BloomTheme.teal : BloomTheme.border))
                    }.buttonStyle(.plain).accessibilityIdentifier("setup-room-\(room.name)")
                        .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }.accessibilityIdentifier("setup-room-choices")
            BloomPlantIdentity(plant: setup.plant)
        }.navigationTitle("A place to grow").bloomAddPage()
            .bloomNativeFooter {
                VStack(spacing: 8) {
                    if setup.plant.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { BloomSelectionHint() }
                    BloomPrimaryAction(title: "Continue") { navigate(.status) }.disabled(setup.plant.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).accessibilityIdentifier("setup-continue-location")
                    Button("Choose later") { setup.plant.location = ""; navigate(.status) }.frame(minHeight: 44)
                }
            }
    }
    private var currentStatus: some View {
        BloomContentPage {
            Text("A first impression · 3 of 3").bloomHeading()
            BloomChoiceList(values: InitialPlantStatus.allCases, selection: $setup.status,
                            title: { $0.rawValue }, identifier: { "setup-status-\($0.rawValue)" })
            BloomPlantIdentity(plant: setup.plant)
        }.navigationTitle("How is it doing?").bloomAddPage()
            .bloomNativeFooter {
                VStack(spacing: 8) {
                    if setup.status == nil { BloomSelectionHint() }
                    BloomPrimaryAction(title: "Add plant", action: save).disabled(setup.status == nil).accessibilityIdentifier("overlay-save-plant")
                    Button("Choose later") { setup.status = .notSure; save() }.frame(minHeight: 44)
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
        navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .toolbar(.hidden, for: .tabBar)
    }
}

