import SwiftUI
import PhotosUI
import UIKit
import Observation

enum PlantAddStep: Hashable { case review }
@MainActor @Observable private final class PlantSetupDraft {
    var plant = Plant(name: "", species: "", asset: "")
    var status: InitialPlantStatus?
    var photoMessage: String?
    var chosenPhoto: PhotosPickerItem?
    var loading = false
    var showingOptionalDetails = false
    var editingCustomLocation = false
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
                BloomPlantSearchField(query: $query)
                    .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 16).background(BloomTheme.canvas)
            }
            .navigationTitle("Add plant").bloomAddPage()
            .navigationDestination(for: PlantAddStep.self) { step in
                switch step {
                case .review: review
                }
            }
    }
    private var review: some View {
        BloomContentPage {
            HStack(alignment: .center, spacing: 14) {
                PlantPortrait(plant: setup.plant).frame(width: 64, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(setup.plant.displayName).font(BloomType.title).foregroundStyle(BloomTheme.ink)
                    if !setup.plant.species.isEmpty {
                        Text(setup.plant.species).font(BloomType.body).italic().foregroundStyle(BloomTheme.secondary)
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
            }.padding(14).background(BloomTheme.surface, in: RoundedRectangle(cornerRadius: 16))
            DisclosureGroup(isExpanded: $setup.showingOptionalDetails) {
                VStack(alignment: .leading, spacing: 0) {
                    optionalPhotoSection
                    Divider().padding(.vertical, 16)
                    optionalGrowingPlaceSection
                    Divider().padding(.vertical, 16)
                    optionalConditionSection
                }.padding(.top, 14)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Add details").font(BloomType.section).foregroundStyle(BloomTheme.ink)
                    Text(optionalDetailsSummary).font(BloomType.supporting).foregroundStyle(BloomTheme.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }.padding(.vertical, 4)
            }
            .padding(16)
            .background(BloomTheme.surface, in: RoundedRectangle(cornerRadius: 16))
            .accessibilityIdentifier("setup-optional-details")
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
                BloomPrimaryAction(title: "Add plant", action: save)
                    .disabled(setup.loading).accessibilityIdentifier("overlay-save-plant")
            }
    }
    private var optionalPhotoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            let hasPhoto = setup.plant.photo != nil
            Text("Photo").bloomHeading()
            HStack(spacing: 14) {
                if hasPhoto {
                    PlantPortrait(plant: setup.plant).frame(width: 64, height: 64).clipShape(RoundedRectangle(cornerRadius: 12))
                }
                PhotosPicker(selection: $setup.chosenPhoto, matching: .images) {
                    HStack(spacing: 10) {
                        BloomSymbol(name: hasPhoto ? "arrow.triangle.2.circlepath" : "plus")
                            .foregroundStyle(BloomTheme.teal)
                        Text(hasPhoto ? "Change photo" : "Add photo")
                            .font(BloomType.body).foregroundStyle(BloomTheme.teal)
                        Spacer(minLength: 0)
                    }.padding(.horizontal, 12).frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                        .background(BloomTheme.canvas, in: RoundedRectangle(cornerRadius: 12))
                        .contentShape(RoundedRectangle(cornerRadius: 12))
                }.buttonStyle(.plain).disabled(setup.loading).accessibilityIdentifier("setup-add-photo")
                    .accessibilityLabel(hasPhoto ? "Change photo" : "Add photo")
            }
            if setup.loading { ProgressView("Opening photo…") }
            if let message = setup.photoMessage { Text(message).font(BloomType.supporting).foregroundStyle(.secondary) }
        }
    }
    private var optionalGrowingPlaceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Where it lives").bloomHeading()
            Picker("Placement", selection: $setup.plant.placement) {
                Text("Not set").tag(PlantPlacement?.none)
                ForEach(PlantPlacement.allCases) { Text($0.rawValue).tag(Optional($0)) }
            }.pickerStyle(.segmented).accessibilityIdentifier("setup-placement")
                .onChange(of: setup.plant.placement) { oldValue, newValue in
                    if oldValue != newValue,
                       (oldValue == .indoor ? PlantRoom.indoor : PlantRoom.outdoor).contains(where: { $0.name == setup.plant.location }) {
                        setup.plant.location = ""
                    }
                    if newValue != nil, !setup.plant.location.isEmpty,
                       !(newValue == .indoor ? PlantRoom.indoor : PlantRoom.outdoor).contains(where: { $0.name == setup.plant.location }) {
                        setup.editingCustomLocation = true
                    }
                }
            if let placement = setup.plant.placement {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 105), spacing: 8)], spacing: 8) {
                    ForEach(placement == .indoor ? PlantRoom.indoor : PlantRoom.outdoor) { room in
                        let selected = setup.plant.location == room.name
                        Button {
                            setup.plant.location = selected ? "" : room.name
                            setup.editingCustomLocation = false
                            BloomFeedback.selection()
                        } label: {
                            Text(room.name).font(BloomType.supporting).foregroundStyle(selected ? BloomTheme.ink : BloomTheme.teal)
                                .frame(maxWidth: .infinity, minHeight: 44).padding(.horizontal, 8)
                                .background(selected ? BloomTheme.selected : BloomTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(selected ? BloomTheme.teal : BloomTheme.border))
                        }.buttonStyle(.plain).accessibilityIdentifier("setup-room-\(room.name)")
                            .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                    let other = PlantRoom.other
                    let selectingOther = setup.editingCustomLocation || setup.plant.location == other.name || (!setup.plant.location.isEmpty && !(placement == .indoor ? PlantRoom.indoor : PlantRoom.outdoor).contains(where: { $0.name == setup.plant.location }))
                    Button {
                        setup.editingCustomLocation = true
                        setup.plant.location = ""
                        BloomFeedback.selection()
                    } label: {
                        Text(other.name).font(BloomType.supporting)
                            .foregroundStyle(selectingOther ? BloomTheme.ink : BloomTheme.teal)
                            .frame(maxWidth: .infinity, minHeight: 44).padding(.horizontal, 8)
                            .background(selectingOther ? BloomTheme.selected : BloomTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(selectingOther ? BloomTheme.teal : BloomTheme.border))
                    }.buttonStyle(.plain).accessibilityIdentifier("setup-room-Other-location")
                        .accessibilityAddTraits(selectingOther ? .isSelected : [])
                }
            }
            if setup.plant.placement == nil || setup.editingCustomLocation {
                TextField("Room or location (optional)", text: $setup.plant.location)
                    .textInputAutocapitalization(.words)
                    .bloomInput().accessibilityIdentifier("setup-custom-location")
            }
        }
    }
    private var optionalConditionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("First impression").bloomHeading()
            VStack(spacing: 0) {
                ForEach(InitialPlantStatus.allCases) { option in
                    let selected = setup.status == option
                    Button {
                        setup.status = selected ? nil : option
                        BloomFeedback.selection()
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(option.rawValue).font(selected ? BloomType.section : BloomType.body).foregroundStyle(BloomTheme.ink)
                            }
                            Spacer(minLength: 8)
                            BloomSymbol(name: selected ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selected ? BloomTheme.teal : BloomTheme.secondary)
                        }.padding(14).frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
                            .background(selected ? BloomTheme.selected : BloomTheme.surface)
                            .contentShape(Rectangle())
                    }.buttonStyle(.plain)
                        .accessibilityLabel(option.rawValue)
                        .accessibilityValue(selected ? "Selected" : "Not selected")
                        .accessibilityAddTraits(selected ? .isSelected : [])
                        .accessibilityIdentifier("setup-status-\(option.rawValue)")
                    if option != InitialPlantStatus.allCases.last { Divider().padding(.leading, 14) }
                }
            }.clipShape(RoundedRectangle(cornerRadius: BloomTheme.cardRadius))
        }
    }
    private var optionalDetailsSummary: String {
        var details: [String] = []
        if setup.plant.photo != nil { details.append("Photo added") }
        if let placement = setup.plant.placement { details.append(placement.rawValue) }
        if !setup.plant.location.isEmpty { details.append(setup.plant.location) }
        if let status = setup.status { details.append("First impression: \(status.rawValue)") }
        return details.isEmpty ? "Optional · Photo, location, or condition" : details.joined(separator: " · ")
    }
    private func select(_ species: PlantSpecies) {
        setup.plant = Plant(name: species.name, species: species.scientific, asset: species.asset)
        setup.status = nil; setup.showingOptionalDetails = false; setup.editingCustomLocation = false; navigate(.review)
    }
    private func addCustom(_ name: String) { setup.plant = Plant(name: name, species: "", asset: ""); setup.status = nil; setup.showingOptionalDetails = false; setup.editingCustomLocation = false; navigate(.review) }
    private func save() {
        setup.plant.location = setup.plant.location.trimmingCharacters(in: .whitespacesAndNewlines)
        if store.addPlant(setup.plant, status: setup.status) {
            store.careFeedback = CareFlowFeedback(plantID: setup.plant.id, title: "\(setup.plant.displayName) added", detail: "Saved to My plants.")
            BloomFeedback.success(); completed(setup.plant.id)
        }
    }
}

private extension View {
    func bloomAddPage() -> some View {
        navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .toolbar(.hidden, for: .tabBar)
    }
}
