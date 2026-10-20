import SwiftUI

struct PlantRoom: Identifiable {
    let name: String
    let symbol: String
    var id: String { name }
    static let indoor = [
        PlantRoom(name: "Living room", symbol: "sofa.fill"), PlantRoom(name: "Kitchen", symbol: "fork.knife"),
        PlantRoom(name: "Dining room", symbol: "chair.fill"), PlantRoom(name: "Bedroom", symbol: "bed.double.fill"),
        PlantRoom(name: "Workspace", symbol: "desktopcomputer"), PlantRoom(name: "Bathroom", symbol: "shower.fill")
    ]
    static let outdoor = [
        PlantRoom(name: "Backyard", symbol: "leaf.fill"), PlantRoom(name: "Front yard", symbol: "house.fill"),
        PlantRoom(name: "Porch", symbol: "door.left.hand.open"), PlantRoom(name: "Patio", symbol: "umbrella.fill"),
        PlantRoom(name: "Balcony", symbol: "sun.max.fill"), PlantRoom(name: "Garden", symbol: "tree.fill")
    ]
}

