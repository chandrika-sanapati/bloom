import Foundation

enum GrowingClimate: String, Codable, CaseIterable, Identifiable {
    case cool = "Cool or cold winters", mild = "Mild winters", dry = "Hot, dry summers", tropical = "Warm and humid year-round"
    var id: Self { self }
}
enum GrowingHemisphere: String, Codable, CaseIterable, Identifiable {
    case north = "Northern", south = "Southern"
    var id: Self { self }
}
enum IndoorSearchLight: String, Codable, CaseIterable, Identifiable {
    case unsure = "Not sure yet", lower = "Lower natural light", bright = "Bright, indirect light"
    var id: Self { self }
}
struct PlantSearchPreferences: Codable, Equatable {
    var area: String
    // Retained as optional legacy fields so older saved preferences still decode.
    var climate: GrowingClimate? = nil
    var hemisphere: GrowingHemisphere? = nil
    var light: IndoorSearchLight
    var location: GrowingLocation? = nil
    var plantTypes: [PlantFormPreference]? = nil
    var selectedTypes: [PlantFormPreference] { plantTypes ?? [] }
    var regionalClimate: GrowingClimate? { location?.climate }
    var displayArea: String { location?.displayName ?? (area.isEmpty ? "Your space" : area) }
}
enum GrowingSeason: String {
    case spring = "Spring", summer = "Summer", autumn = "Autumn", winter = "Winter", yearRound = "Year-round", unknown = "Indoor picks"
    var symbol: String { switch self { case .spring: "leaf"; case .summer: "sun.max"; case .autumn: "leaf.fill"; case .winter: "snowflake"; case .yearRound: "sun.haze"; case .unknown: "leaf" } }
}
struct PlantSearchSuggestion: Identifiable {
    let species: PlantSpecies
    let reason: String
    let ownedCount: Int
    var matchesTypePreference = false
    var id: String { species.id }
}
enum PlantSearchEngine {
    static func normalized(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }
    static func season(for profile: PlantSearchPreferences, date: Date, calendar: Calendar = .current) -> GrowingSeason {
        // Wet/dry seasons vary locally; don't invent a temperate season for the tropics.
        guard let location = profile.location, location.valid else { return .unknown }
        if location.climate == .tropical { return .yearRound }
        if abs(location.latitude) < 23.5 { return .unknown }
        let month = calendar.component(.month, from: date)
        let adjusted = location.latitude >= 0 ? month : ((month + 5) % 12) + 1
        switch adjusted { case 3...5: return .spring; case 6...8: return .summer; case 9...11: return .autumn; default: return .winter }
    }
    static func aliases(for species: PlantSpecies) -> [String] {
        switch species.scientific {
        case "Dracaena trifasciata": ["Snake plant", "Sansevieria", "Mother-in-law's tongue"]
        case "Monstera deliciosa": ["Monstera", "Swiss cheese plant"]
        case "Ficus elastica": ["Rubber plant", "Rubber tree"]
        case "Epipremnum aureum": ["Pothos", "Golden pothos", "Devil’s ivy", "Devil's ivy"]
        default: [species.name]
        }
    }
    static func ownedCount(_ species: PlantSpecies, plants: [Plant]) -> Int {
        plants.filter { plant in
            if !plant.species.isEmpty { return normalized(plant.species) == normalized(species.scientific) }
            return ([species.name, species.scientific] + aliases(for: species)).contains { normalized($0) == normalized(plant.name) }
        }.count
    }
    static func results(query: String) -> [PlantSpecies] {
        let terms = normalized(query).split(separator: " ")
        return PlantSpecies.catalog.filter { species in
            let text = normalized(([species.name, species.scientific] + aliases(for: species)).joined(separator: " "))
            return terms.allSatisfy { text.contains($0) }
        }.sorted { a, b in
            let exactA = normalized(a.name) == normalized(query), exactB = normalized(b.name) == normalized(query)
            return exactA != exactB ? exactA : a.name < b.name
        }
    }
    static func suggestions(profile: PlantSearchPreferences?, plants: [Plant], date: Date = .now, calendar: Calendar = .current) -> [PlantSearchSuggestion] {
        let season = profile.map { self.season(for: $0, date: date, calendar: calendar) }
        return PlantSpecies.catalog.map { species -> (PlantSearchSuggestion, Int) in
            let owned = ownedCount(species, plants: plants)
            var score = owned == 0 ? 10 : 0
            let matchingType = profile?.selectedTypes.first { species.forms.contains($0) }
            var reason = species.light == .low ? "Tolerates lower light; still needs natural light." : "For a spot with bright, indirect light."
            if let profile {
                if profile.light == .lower && species.light == .low {
                    score += 100; reason = "A lower-light option for the spot you described. It still needs natural light."
                } else if profile.light == .bright && species.light == .indirect {
                    score += 100; reason = "Matches the bright, indirect light in your space."
                } else if profile.light == .lower {
                    reason = "Needs a brighter spot than the lower-light space you described."
                }
                if species.asset == "snake" && (season == .autumn || season == .winter) && profile.regionalClimate != .tropical {
                    score += 20
                    if profile.light == .unsure { reason = "An option for lower indoor light as days shorten. Avoid cold windows and draughts." }
                }
                if species.asset == "monstera" && profile.regionalClimate == .tropical {
                    score += 20
                    if profile.light != .lower { reason = "Enjoys warmth and moderate humidity, with bright, filtered light indoors." }
                }
            }
            if let matchingType {
                score += 60
                reason += " \(matchingType.rawValue) growth matches your preferences."
            }
            return (PlantSearchSuggestion(species: species, reason: reason, ownedCount: owned, matchesTypePreference: matchingType != nil), score)
        }.sorted { a, b in
            if a.1 != b.1 { return a.1 > b.1 }
            return (PlantSpecies.catalog.firstIndex { $0.id == a.0.id } ?? 0) < (PlantSpecies.catalog.firstIndex { $0.id == b.0.id } ?? 0)
        }.map(\.0)
    }
    static func seasonalNote(_ profile: PlantSearchPreferences, date: Date = .now) -> String {
        switch season(for: profile, date: date) {
        case .autumn, .winter:
            return profile.regionalClimate == .cool ? "Shorter days make indoor light worth checking. Keep these houseplants warm and away from cold draughts." : "As days shorten, check the light in the room where your new plant will live."
        case .spring: return "Longer days can help indoor growth. Choose for your room's light, and keep tender houseplants protected from cold."
        case .summer: return profile.regionalClimate == .dry ? "Bright sun can be intense. Give these houseplants filtered indoor light, away from hot glass." : "Protect indoor foliage from strong direct sun. Your room's light matters more than the season."
        case .unknown: return profile.location == nil ? "Choose an area for seasonal context. Your indoor light and plant preferences can guide picks right away." : "Picks use your indoor light and plant preferences. Local seasonal patterns can vary."
        case .yearRound: return "Warm conditions can suit tropical foliage. Indoor light and humidity still matter; local wet and dry seasons vary."
        }
    }
}

extension BloomStore {
    var plantSearchPreferences: PlantSearchPreferences? { garden.plantSearchPreferences }
    var recentPlantSearches: [String] { garden.recentPlantSearches ?? [] }
    func savePlantSearchPreferences(_ preferences: PlantSearchPreferences?) -> Bool {
        guard var ready = preferences else { return commit { $0.plantSearchPreferences = nil } }
        ready.area = String(ready.area.trimmingCharacters(in: .whitespacesAndNewlines).prefix(80))
        var settings = appPreferences; settings.personalizedPicks = true
        return commit { $0.plantSearchPreferences = ready; $0.appPreferences = settings }
    }
    func rememberPlantSearch(_ query: String) {
        let clean = String(query.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ").prefix(80))
        guard clean.count >= 2 else { return }
        let existing = recentPlantSearches.filter { PlantSearchEngine.normalized($0) != PlantSearchEngine.normalized(clean) }
        let next = Array(([clean] + existing).prefix(5))
        guard next != recentPlantSearches else { return }
        _ = commit { $0.recentPlantSearches = next }
    }
    func clearPlantSearches() { _ = commit { $0.recentPlantSearches = [] } }
}
