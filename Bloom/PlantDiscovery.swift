import SwiftUI

struct BloomPlantSearchField: View {
    @Binding var query: String
    var submitted: () -> Void = {}
    @FocusState private var focused: Bool
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(BloomTheme.secondary).accessibilityHidden(true)
            TextField("Search plants", text: $query).font(.body)
                .autocorrectionDisabled().textInputAutocapitalization(.never).submitLabel(.search)
                .focused($focused).onSubmit { submitted(); focused = false }
                .accessibilityIdentifier("plant-search-field")
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(BloomTheme.secondary).frame(width: 28, height: 44)
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
    var reason: String? = nil
    var ownedCount = 0
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Group {
                if species.asset.isEmpty {
                    ZStack {
                        BloomTone.blue.surface
                        PlantFormArtwork(form: species.forms.first ?? .upright).padding(24)
                        Text("Illustration").font(.caption2).foregroundStyle(BloomTheme.secondary).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing).padding(10)
                    }
                } else { PlantPortrait(plant: Plant(name: species.name, species: species.scientific, asset: species.asset)) }
            }.frame(height: typeSize.isAccessibilitySize ? 280 : 196)
                .overlay(alignment: .bottomLeading) {
                    ZStack(alignment: .bottomLeading) {
                        LinearGradient(colors: [.clear, .black.opacity(0.75)], startPoint: .top, endPoint: .bottom)
                        Text(species.name).font(.headline.weight(.semibold)).foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true).padding(12)
                    }.frame(minHeight: 88)
                }
            VStack(alignment: .leading, spacing: 9) {
                if ownedCount > 0 {
                    Label("\(ownedCount) in My plants", systemImage: "checkmark.circle")
                        .font(.caption.weight(.medium)).foregroundStyle(BloomTheme.teal)
                }
                StatusTag(text: "\(species.care.rawValue) care", tone: species.care == .easy ? .teal : .yellow)
                Label(species.light.rawValue, systemImage: species.light.symbol)
                    .font(.footnote).foregroundStyle(BloomTheme.secondary).fixedSize(horizontal: false, vertical: true)
                if let reason { Text(reason).font(.caption).foregroundStyle(BloomTheme.secondary).fixedSize(horizontal: false, vertical: true) }
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
    @State private var personalizing = false
    private var search: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var profile: PlantSearchPreferences? { store.discoveryPreferences }
    private var suggestions: [PlantSearchSuggestion] { PlantSearchEngine.suggestions(profile: profile, plants: store.garden.plants) }
    private var preferred: [PlantSearchSuggestion] { suggestions.filter { $0.matchesTypePreference } }
    private var otherShapes: [PlantSearchSuggestion] { suggestions.filter { !$0.matchesTypePreference } }
    private var hasTypes: Bool { !(profile?.selectedTypes.isEmpty ?? true) }
    private var results: [PlantSpecies] { PlantSearchEngine.results(query: search) }
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if search.isEmpty {
                areaCard
                if !store.recentPlantSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Recent searches").font(.headline)
                            Spacer()
                            Button("Clear", action: store.clearPlantSearches).font(.subheadline).frame(minHeight: 44).accessibilityIdentifier("clear-recent-searches")
                        }
                        ScrollView(.horizontal) {
                            HStack(spacing: 10) {
                                ForEach(store.recentPlantSearches, id: \.self) { recent in
                                    Button { query = recent } label: {
                                        Label(recent, systemImage: "clock").frame(minHeight: 28)
                                    }.buttonStyle(.bordered).accessibilityIdentifier("recent-search-\(recent)")
                                }
                            }
                        }.scrollIndicators(.hidden)
                    }
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text(profile == nil ? "Choose a plant" : (profile?.location == nil ? "For your space" : "Seasonal picks")).font(BloomTheme.section)
                    Text(profile == nil ? "Start with a familiar face, or search to add your own." : "Ideas for your indoor space. Tap a plant to make it yours.")
                        .font(.subheadline).foregroundStyle(BloomTheme.secondary)
                }
                if hasTypes {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.square.fill").foregroundStyle(BloomTheme.teal)
                        Text(profile!.selectedTypes.map(\.rawValue).joined(separator: " · ")).font(.subheadline.weight(.medium))
                    }.accessibilityIdentifier("search-selected-types")
                    if !preferred.isEmpty { plantGrid(preferred) }
                    else { Text("No matching shape in our small catalog yet. You can search for any plant and add it by name.").font(.subheadline).foregroundStyle(.secondary) }
                    if !otherShapes.isEmpty {
                        Text("Other shapes to explore").font(BloomTheme.section)
                        plantGrid(otherShapes)
                    }
                } else { plantGrid(suggestions) }
                if profile != nil {
                    Text("Curated indoor picks for your light, plant shapes, and location. Local popularity and live weather aren't measured.")
                        .font(.footnote).foregroundStyle(BloomTheme.secondary)
                    DisclosureGroup("How these picks work") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your light and selected plant shapes guide these picks. A chosen city supplies coordinates for the season; NASA POWER monthly climate data adds regional context. These are indoor ideas, not outdoor hardiness or availability advice.")
                            Link("Location search · Open-Meteo / GeoNames", destination: URL(string: "https://open-meteo.com/en/docs/geocoding-api")!)
                            Link("Regional climate · NASA POWER", destination: URL(string: "https://power.larc.nasa.gov/docs/services/api/temporal/climatology/")!)
                            Link("Trailing and climbing · RHS", destination: URL(string: "https://www.rhs.org.uk/plants/epipremnum/growing-guide")!)
                            Link("Indoor light · University of Minnesota", destination: URL(string: "https://extension.umn.edu/garden-and-home/yard-and-garden/gardening-in-minnesota/lighting-for-indoor-plants")!)
                            Link("Choosing houseplants · RHS", destination: URL(string: "https://www.rhs.org.uk/plants/types/houseplants/winter-interest-houseplants-care")!)
                        }.font(.footnote).padding(.top, 10)
                    }.font(.subheadline)
                }
            } else {
                HStack {
                    Text("Search results").font(BloomTheme.section)
                    Spacer()
                    Text("\(results.count)").foregroundStyle(.secondary)
                }
                Text("Searching all catalog plants, regardless of your area settings.").font(.subheadline).foregroundStyle(BloomTheme.secondary)
                if results.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "leaf").font(.largeTitle).foregroundStyle(BloomTheme.teal)
                        Text("No catalog match yet").font(.headline)
                        Text("You can still add \"\(search)\" by name and keep its care records.").font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }.frame(maxWidth: .infinity).padding(.vertical, 20)
                } else {
                    plantGrid(results.map { PlantSearchSuggestion(species: $0, reason: "", ownedCount: PlantSearchEngine.ownedCount($0, plants: store.garden.plants)) })
                }
                Button { addCustom(search) } label: { Label("Add \"\(search)\" by name", systemImage: "plus").frame(maxWidth: .infinity, minHeight: 32) }
                    .buttonStyle(.bordered).accessibilityIdentifier("add-custom-search")
            }
            Text("Can't find it? Enter any plant name to add your own.").font(.footnote).foregroundStyle(BloomTheme.secondary)
        }.sheet(isPresented: $personalizing) { PlantSearchPersonalizationView() }
    }
    private var areaCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                BloomIconTile(symbol: profile.map { PlantSearchEngine.season(for: $0, date: .now).symbol } ?? "leaf", tone: .yellow)
                VStack(alignment: .leading, spacing: 5) {
                    Text(profile.map { "\($0.displayArea) · \(PlantSearchEngine.season(for: $0, date: .now).rawValue)" } ?? "Find a plant for your space").font(.headline)
                    Text(profile.map { PlantSearchEngine.seasonalNote($0) } ?? "Find your city, choose your light, and pick the plant shapes you love.")
                        .font(.subheadline).foregroundStyle(BloomTheme.secondary)
                }
            }
            Button(profile == nil ? "Personalize picks" : "Edit area & preferences") { personalizing = true }
                .font(.subheadline.weight(.semibold)).frame(minHeight: 44).accessibilityIdentifier("personalize-plant-search")
        }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(BloomTone.yellow.surface, in: RoundedRectangle(cornerRadius: BloomTheme.cardRadius))
    }
    private func plantGrid(_ items: [PlantSearchSuggestion]) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14, alignment: .top), count: typeSize.isAccessibilitySize ? 1 : 2), alignment: .leading, spacing: 16) {
            ForEach(items) { item in
                Button { select(item.species) } label: {
                    BloomDiscoveryCard(species: item.species, reason: search.isEmpty && profile != nil ? item.reason : nil, ownedCount: item.ownedCount)
                }.buttonStyle(BloomPressStyle()).accessibilityElement(children: .ignore).accessibilityAddTraits(.isButton)
                    .accessibilityLabel("\(item.species.name), \(item.species.care.rawValue) care, \(item.species.light.rawValue)" + (item.ownedCount > 0 ? ", \(item.ownedCount) in My plants" : "") + (search.isEmpty && profile != nil ? ", \(item.reason)" : ""))
                    .accessibilityHint(item.ownedCount > 0 ? "Review and add another of this plant" : "Review and add this plant")
                    .accessibilityIdentifier("select-species-\(item.species.name)")
            }
        }
    }
}
