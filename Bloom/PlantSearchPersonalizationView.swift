import SwiftUI
import CoreLocation

struct PlantSearchPersonalizationView: View {
    @Environment(BloomStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var location: GrowingLocation?
    @State private var legacyArea = ""
    @State private var query = ""
    @State private var cities: [GrowingLocation] = []
    @State private var editingLocation = true
    @State private var light = IndoorSearchLight.unsure
    @State private var types: Set<PlantFormPreference> = []
    @State private var status: String?
    @State private var busy: String?
    @State private var initialized = false
    @State private var operation: Task<Void, Never>?
    @State private var locator = PlantLocationLocator()
    private let service = GrowingLocationService()
    private var hasUnselectedCity: Bool {
        editingLocation && !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && query != legacyArea
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if !store.appPreferences.personalizedPicks {
                        Text("Saving these choices turns personalized picks on.").font(.footnote).foregroundStyle(BloomTheme.secondary)
                    }
                    areaSection
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Where will your plant live?").font(BloomTheme.section)
                        VStack(spacing: 0) {
                            ForEach(IndoorSearchLight.allCases) { option in
                                Button { light = option; BloomFeedback.selection() } label: {
                                    HStack(spacing: 12) {
                                        Text(option.rawValue).font(.subheadline)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        selectionMark(light == option, multiple: false)
                                    }.padding(.horizontal, 14).frame(minHeight: 46).contentShape(Rectangle())
                                }.buttonStyle(.plain).accessibilityElement(children: .ignore).accessibilityAddTraits(.isButton)
                                    .accessibilityLabel(option.rawValue).accessibilityValue(light == option ? "Selected" : "Not selected")
                                    .accessibilityAddTraits(light == option ? .isSelected : [])
                                    .accessibilityIdentifier("search-light-\(option.rawValue)")
                                if option != IndoorSearchLight.allCases.last { Divider().padding(.leading, 14) }
                            }
                        }.background(BloomTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(BloomTheme.border, lineWidth: 1))
                        Text("Choose its indoor light. Lower light still needs daylight.").font(.footnote).foregroundStyle(BloomTheme.secondary)
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeading("What plants do you like?", detail: "Choose one or more. None selected means all shapes.")
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12, alignment: .top), count: typeSize.isAccessibilitySize ? 1 : 2), spacing: 12) {
                            ForEach(PlantFormPreference.allCases) { option in
                                Button {
                                    if types.contains(option) { types.remove(option) } else { types.insert(option) }
                                    BloomFeedback.selection()
                                } label: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            PlantFormArtwork(form: option).frame(height: 60)
                                            selectionMark(types.contains(option), multiple: true)
                                        }
                                        Text(option.rawValue).font(.subheadline.weight(.semibold))
                                    }.frame(maxWidth: .infinity, alignment: .leading).padding(12)
                                        .background(types.contains(option) ? BloomTheme.selected : BloomTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(types.contains(option) ? BloomTheme.teal : BloomTheme.border, lineWidth: types.contains(option) ? 2 : 1))
                                }.buttonStyle(.plain).accessibilityElement(children: .ignore).accessibilityAddTraits(.isButton)
                                    .accessibilityLabel("\(option.rawValue), \(option.subtitle)")
                                    .accessibilityValue(types.contains(option) ? "Selected" : "Not selected")
                                    .accessibilityAddTraits(types.contains(option) ? .isSelected : [])
                                    .accessibilityIdentifier("search-type-\(option.rawValue)")
                            }
                        }
                        if !types.isEmpty { Text("\(types.count) selected").font(.footnote.weight(.medium)).foregroundStyle(BloomTheme.teal).accessibilityIdentifier("selected-plant-types") }
                    }
                    if store.plantSearchPreferences != nil {
                        Button("Turn off personalized picks") {
                            if store.setPersonalizedPicks(false) { dismiss() }
                        }.frame(minHeight: 44).accessibilityIdentifier("reset-plant-personalization")
                    }
                }.padding(20)
            }.background(BloomTheme.canvas).scrollDismissesKeyboard(.interactively)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    Button {
                        light = .unsure; types.removeAll(); BloomFeedback.selection()
                    } label: {
                        Label("Reset preferences", systemImage: "arrow.counterclockwise")
                            .font(.subheadline.weight(.medium)).frame(maxWidth: .infinity, minHeight: 44)
                    }.buttonStyle(.plain)
                        .foregroundStyle(light == .unsure && types.isEmpty ? BloomTheme.secondary : BloomTheme.teal)
                        .disabled(light == .unsure && types.isEmpty)
                        .accessibilityHint("Clears light and plant-type choices. Keeps your city. Tap Save to apply.")
                        .accessibilityIdentifier("reset-search-choices")
                        .padding(.horizontal, 20).padding(.vertical, 6)
                        .background(.bar)
                        .overlay(alignment: .top) { Rectangle().fill(BloomTheme.border).frame(height: 0.5) }
                }
                .navigationTitle("Your growing space").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let preferences = PlantSearchPreferences(area: location?.displayName ?? legacyArea, light: light, location: location, plantTypes: PlantFormPreference.allCases.filter { types.contains($0) })
                            if store.savePlantSearchPreferences(preferences) { dismiss() }
                        }.disabled(busy != nil || hasUnselectedCity).accessibilityIdentifier("save-search-personalization")
                    }
                }
                .onAppear {
                    guard !initialized else { return }; initialized = true
                    if let saved = store.plantSearchPreferences {
                        location = saved.location; legacyArea = saved.area; light = saved.light; types = Set(saved.selectedTypes)
                        editingLocation = saved.location == nil; query = saved.location == nil ? saved.area : ""
                    }
                }
                .onDisappear { operation?.cancel(); locator.cancel() }
        }
    }
    private var areaSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your area").font(BloomTheme.section)
            HStack(spacing: 8) {
                Image(systemName: editingLocation ? "magnifyingglass" : "mappin.and.ellipse")
                    .foregroundStyle(BloomTheme.secondary).accessibilityHidden(true)
                if editingLocation {
                    TextField("City or postal code", text: $query).textContentType(.addressCity).autocorrectionDisabled()
                        .submitLabel(.search).onSubmit(searchCity).disabled(busy != nil).accessibilityIdentifier("search-growing-area")
                        .onChange(of: query) { _, _ in cities = []; status = nil }
                    if query.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 {
                        Button("Find", action: searchCity).font(.subheadline.weight(.medium)).disabled(busy != nil)
                            .frame(minHeight: 44).accessibilityIdentifier("find-search-city")
                    }
                } else if let location {
                    Button {
                        editingLocation = true; query = ""; cities = []; status = nil
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(location.displayName).font(.subheadline.weight(.semibold))
                            if !location.detail.isEmpty { Text(location.detail).font(.caption).foregroundStyle(BloomTheme.secondary) }
                        }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading).contentShape(Rectangle())
                    }.buttonStyle(.plain).disabled(busy != nil).accessibilityLabel("Change location, \(location.displayName)")
                        .accessibilityIdentifier("change-search-location")
                }
                Divider().frame(height: 24)
                Button(action: locateMe) {
                    Image(systemName: "location.fill").font(.body).frame(width: 44, height: 44)
                }.buttonStyle(.plain).foregroundStyle(BloomTheme.teal).disabled(busy != nil)
                    .accessibilityLabel("Locate me").accessibilityHint("Use your current city for seasonal picks")
                    .accessibilityIdentifier("search-locate-me")
            }.padding(.leading, 14).padding(.trailing, 4).padding(.vertical, 4)
                .background(BloomTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(BloomTheme.border, lineWidth: 1))
            if location != nil || !legacyArea.isEmpty {
                Button("Remove saved area", role: .destructive) {
                    operation?.cancel(); operation = nil; locator.cancel()
                    location = nil; legacyArea = ""; query = ""; cities = []; editingLocation = true; status = nil; busy = nil
                }.font(.footnote).frame(minHeight: 44).disabled(busy != nil).accessibilityIdentifier("remove-search-area")
            }
            if editingLocation {
                if let location {
                    HStack {
                        Text("Current: \(location.displayName)").font(.footnote).foregroundStyle(BloomTheme.secondary)
                        Spacer()
                        Button("Keep current location") { editingLocation = false; query = ""; cities = []; status = nil }.font(.footnote).frame(minHeight: 44)
                    }
                } else if !legacyArea.isEmpty {
                    Text("Previously chosen: \(legacyArea). Select a city to update seasonal context.").font(.footnote).foregroundStyle(BloomTheme.secondary)
                }
                ForEach(cities) { city in
                    Button { choose(city) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) { Text(city.displayName).font(.subheadline.weight(.semibold)); Text(city.detail).font(.caption).foregroundStyle(.secondary) }
                            Spacer(); Image(systemName: "plus.circle").foregroundStyle(BloomTheme.teal)
                        }.padding(12).frame(maxWidth: .infinity, alignment: .leading).background(BloomTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                    }.buttonStyle(.plain).disabled(busy != nil).accessibilityIdentifier("search-city-\(city.name)")
                }
            }
            if let busy { ProgressView(busy).font(.subheadline).accessibilityIdentifier("search-location-progress") }
            if let status { Text(status).font(.footnote).foregroundStyle(BloomTheme.secondary).accessibilityIdentifier("search-location-status") }
            if let location, location.climate == nil && busy == nil {
                Button("Retry seasonal context") { choose(location) }.font(.subheadline).frame(minHeight: 44)
            }
            DisclosureGroup("Location is optional") {
                Text("Your city supplies seasonal context. Locate me requests access only when tapped. City search uses Open-Meteo; approximate regional coordinates are used for NASA POWER climate data.")
                    .font(.footnote).foregroundStyle(BloomTheme.secondary).padding(.top, 6)
            }.font(.footnote).foregroundStyle(BloomTheme.secondary)
        }
    }
    private func sectionHeading(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) { Text(title).font(BloomTheme.section); Text(detail).font(.subheadline).foregroundStyle(BloomTheme.secondary) }
    }
    private func selectionMark(_ selected: Bool, multiple: Bool) -> some View {
        Image(systemName: selected ? (multiple ? "checkmark.square.fill" : "checkmark.circle.fill") : (multiple ? "square" : "circle"))
            .font(.title3).foregroundStyle(selected ? BloomTheme.teal : BloomTheme.secondary.opacity(0.5)).accessibilityHidden(true)
    }
    private func searchCity() {
        guard busy == nil else { return }
        busy = "Finding cities…"; status = nil; cities = []
        operation = Task {
            defer { busy = nil }
            do {
                let matches = try await service.search(query); try Task.checkCancellation(); cities = matches
                if matches.isEmpty { status = "No matching city. Try a nearby city or add a country, such as Berlin, Germany." }
            } catch { if !Task.isCancelled { status = "City search is unavailable. Try again when connected, or continue with light and plant preferences." } }
        }
    }
    private func choose(_ city: GrowingLocation) {
        guard busy == nil else { return }
        location = city; query = ""; cities = []; editingLocation = false; status = nil
        busy = "Adding seasonal context…"
        operation = Task {
            defer { busy = nil }
            do { let ready = try await service.addingClimate(to: city); try Task.checkCancellation(); location = ready }
            catch { if !Task.isCancelled { status = "City selected. Regional climate data is unavailable for now. You can save and retry later." } }
        }
    }
    private func locateMe() {
        guard busy == nil else { return }; status = nil; busy = "Finding your city…"
        operation = Task {
            do {
                let city: GrowingLocation
                if ProcessInfo.processInfo.arguments.contains("--uitesting") {
                    guard ProcessInfo.processInfo.arguments.contains("--uitesting-location-success") else { throw CLError(.denied) }
                    var simulated = GrowingLocation.berlin; simulated.climate = nil; city = simulated
                } else { city = try await locator.locate() }
                try Task.checkCancellation(); busy = nil; choose(city)
            } catch {
                busy = nil
                if !Task.isCancelled {
                    status = "We couldn't access your location. You can search for a city instead. If access is off, you can enable it in iOS Settings."
                }
            }
        }
    }
}
