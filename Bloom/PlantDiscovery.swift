import SwiftUI

struct BloomPlantSearchField: View {
    @Binding var query: String
    @FocusState private var focused: Bool
    var body: some View {
        HStack(spacing: 8) {
            BloomSymbol(name: "magnifyingglass").foregroundStyle(BloomTheme.secondary).accessibilityHidden(true)
            TextField("Search plant", text: $query).accessibilityLabel("Search plants").font(BloomType.body)
                .autocorrectionDisabled().textInputAutocapitalization(.never).submitLabel(.search)
                .focused($focused).onSubmit { focused = false }
                .accessibilityIdentifier("plant-search-field")
            if !query.isEmpty {
                Button { query = "" } label: {
                    BloomSymbol(name: "xmark.circle.fill").foregroundStyle(BloomTheme.secondary).frame(width: 28, height: 44)
                }.buttonStyle(.plain).accessibilityLabel("Clear search").accessibilityIdentifier("plant-search-clear")
            }

        }.padding(.leading, 14).padding(.trailing, 5).padding(.vertical, 4).frame(minHeight: 54)
            .onDisappear { focused = false }
            .foregroundStyle(BloomTheme.ink)
            .background(BloomTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(focused ? BloomTheme.teal : BloomTheme.border, lineWidth: focused ? 1.5 : 1))
    }
}

struct BloomDiscoveryCard: View {
    let species: PlantSpecies
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Group {
                PlantPortrait(plant: Plant(name: species.name, species: species.scientific, asset: species.asset))
            }.frame(height: typeSize.isAccessibilitySize ? 280 : 196)
                .overlay(alignment: .bottomLeading) {
                    ZStack(alignment: .bottomLeading) {
                        LinearGradient(colors: [.clear, .black.opacity(0.75)], startPoint: .top, endPoint: .bottom)
                        Text(species.name).font(BloomType.section).foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true).padding(12)
                    }.frame(minHeight: 88)
                }
            VStack(alignment: .leading, spacing: 9) {
                StatusTag(text: "\(species.care.rawValue) care", tone: species.care == .easy ? .teal : .yellow)
                Label(species.light.rawValue, systemImage: species.light.symbol)
                    .font(BloomType.supporting).foregroundStyle(BloomTheme.secondary).fixedSize(horizontal: false, vertical: true)
            }.padding(12).frame(maxWidth: .infinity, alignment: .leading)
        }.background(BloomTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: BloomTheme.cardRadius, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: BloomTheme.cardRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: BloomTheme.cardRadius, style: .continuous).strokeBorder(BloomTheme.border.opacity(0.7), lineWidth: 1))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }
}

struct PlantDiscoveryView: View {
    @Binding var query: String
    var select: (PlantSpecies) -> Void
    var addCustom: (String) -> Void
    @Environment(BloomStore.self) private var store
    @Environment(\.dynamicTypeSize) private var typeSize
    private var search: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var results: [PlantSpecies] { PlantSearchEngine.results(query: search) }
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if search.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Choose a plant").bloomHeading()
                    Text("Browse our indoor plants, or search to add your own.")
                        .font(BloomType.body).foregroundStyle(BloomTheme.secondary)
                }
                plantGrid(PlantSpecies.catalog)
            } else {
                HStack {
                    Text("Search results").bloomHeading()
                    Spacer()
                    if !results.isEmpty { Text("\(results.count)").foregroundStyle(.secondary) }
                }
                if results.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No catalog match yet").font(BloomType.section)
                        Text("Add it as your own plant. You can edit its details later.")
                            .font(BloomType.body).foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
                } else {
                    plantGrid(results)
                }
                if results.isEmpty {
                    Button { addCustom(search) } label: { BloomActionLabel(title: "Add \"\(search)\"") }
                        .buttonStyle(BloomPrimaryButtonStyle()).accessibilityIdentifier("add-custom-search")
                }
            }
        }
    }
    private func plantGrid(_ items: [PlantSpecies]) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14, alignment: .top), count: typeSize.isAccessibilitySize ? 1 : 2), alignment: .leading, spacing: 16) {
            ForEach(items) { species in
                Button { select(species) } label: {
                    BloomDiscoveryCard(species: species)
                }.buttonStyle(BloomPressStyle()).accessibilityElement(children: .ignore).accessibilityAddTraits(.isButton)
                    .accessibilityLabel("\(species.name), \(species.care.rawValue) care, \(species.light.rawValue)")
                    .accessibilityHint("Review and add this plant")
                    .accessibilityIdentifier("select-species-\(species.name)")
            }
        }
    }
}
