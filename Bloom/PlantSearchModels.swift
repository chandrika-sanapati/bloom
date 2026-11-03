import Foundation

// Legacy discovery preference schema is retained solely to decode old gardens.
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

struct GrowingLocation: Codable, Equatable, Identifiable {
    var name: String
    var region: String
    var country: String
    var latitude: Double
    var longitude: Double
    var climate: GrowingClimate?
    var id: String { "\(name)-\(latitude)-\(longitude)" }
}

enum PlantFormPreference: String, Codable, CaseIterable, Identifiable {
    case upright = "Upright", bushy = "Bushy", trailing = "Trailing", climbing = "Climbing"
    var id: Self { self }
    var subtitle: String {
        switch self { case .upright: "Tall, structured shapes"; case .bushy: "Full, leafy shapes"; case .trailing: "Hanging stems"; case .climbing: "Growing up a support" }
    }
}

struct PlantSearchPreferences: Codable, Equatable {
    var area: String
    var climate: GrowingClimate? = nil
    var hemisphere: GrowingHemisphere? = nil
    var light: IndoorSearchLight
    var location: GrowingLocation? = nil
    var plantTypes: [PlantFormPreference]? = nil
}

// Search is deliberately limited to the small curated catalog; no profile ranking or location use.
enum PlantSearchEngine {
    static func normalized(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
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

    static func results(query: String) -> [PlantSpecies] {
        let terms = normalized(query).split(separator: " ")
        return PlantSpecies.catalog.filter { species in
            let searchable = normalized(([species.name, species.scientific] + aliases(for: species)).joined(separator: " "))
            return terms.allSatisfy { searchable.contains($0) }
        }.sorted { lhs, rhs in
            let lhsExact = normalized(lhs.name) == normalized(query)
            let rhsExact = normalized(rhs.name) == normalized(query)
            return lhsExact != rhsExact ? lhsExact : lhs.name < rhs.name
        }
    }
}
