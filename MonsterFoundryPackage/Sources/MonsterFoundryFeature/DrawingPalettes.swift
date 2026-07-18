import SwiftUI

struct PaletteSwatch: Identifiable {
    let name: String
    let color: Color

    var id: String { name }

    init(_ name: String, _ red: Double, _ green: Double, _ blue: Double) {
        self.name = name
        color = Color(red: red / 255, green: green / 255, blue: blue / 255)
    }
}

enum DrawingPalette: String, CaseIterable, Identifiable {
    case crayonBox
    case sunset
    case ocean
    case meadow
    case pastel
    case cosmic

    var id: Self { self }

    var title: String {
        switch self {
        case .crayonBox: "Crayon Box"
        case .sunset: "Sunset"
        case .ocean: "Ocean"
        case .meadow: "Meadow"
        case .pastel: "Pastel"
        case .cosmic: "Cosmic"
        }
    }

    var symbol: String {
        switch self {
        case .crayonBox: "paintpalette.fill"
        case .sunset: "sun.horizon.fill"
        case .ocean: "water.waves"
        case .meadow: "leaf.fill"
        case .pastel: "cloud.fill"
        case .cosmic: "sparkles"
        }
    }

    var swatches: [PaletteSwatch] {
        switch self {
        case .crayonBox:
            [
                PaletteSwatch("Graphite", 26, 23, 31),
                PaletteSwatch("Plum", 64, 20, 87),
                PaletteSwatch("Cherry", 229, 57, 53),
                PaletteSwatch("Tangerine", 251, 140, 0),
                PaletteSwatch("Sunshine", 253, 216, 53),
                PaletteSwatch("Grass", 67, 160, 71),
                PaletteSwatch("Sky", 30, 136, 229),
                PaletteSwatch("Grape", 142, 36, 170),
                PaletteSwatch("Bubblegum", 240, 98, 146),
                PaletteSwatch("Chocolate", 121, 85, 72),
            ]
        case .sunset:
            [
                PaletteSwatch("Dusk", 94, 53, 177),
                PaletteSwatch("Magenta Glow", 216, 27, 96),
                PaletteSwatch("Coral", 255, 112, 67),
                PaletteSwatch("Amber", 255, 179, 0),
                PaletteSwatch("Peach", 255, 204, 128),
                PaletteSwatch("Rose", 244, 143, 177),
                PaletteSwatch("Night Blue", 40, 53, 147),
                PaletteSwatch("Warm Sand", 239, 203, 164),
            ]
        case .ocean:
            [
                PaletteSwatch("Abyss", 13, 71, 161),
                PaletteSwatch("Lagoon", 0, 151, 167),
                PaletteSwatch("Seafoam", 128, 203, 196),
                PaletteSwatch("Wave", 41, 182, 246),
                PaletteSwatch("Sand", 255, 224, 178),
                PaletteSwatch("Coral Reef", 255, 138, 101),
                PaletteSwatch("Kelp", 85, 139, 47),
                PaletteSwatch("Shell", 248, 187, 208),
            ]
        case .meadow:
            [
                PaletteSwatch("Forest", 27, 94, 32),
                PaletteSwatch("Fern", 46, 125, 50),
                PaletteSwatch("New Leaf", 124, 179, 66),
                PaletteSwatch("Buttercup", 255, 234, 0),
                PaletteSwatch("Poppy", 230, 74, 25),
                PaletteSwatch("Cornflower", 92, 107, 192),
                PaletteSwatch("Earth", 141, 110, 99),
                PaletteSwatch("Mushroom", 215, 204, 200),
            ]
        case .pastel:
            [
                PaletteSwatch("Blush", 248, 187, 208),
                PaletteSwatch("Mint", 178, 223, 219),
                PaletteSwatch("Baby Blue", 179, 229, 252),
                PaletteSwatch("Lemon", 255, 249, 196),
                PaletteSwatch("Lilac", 209, 196, 233),
                PaletteSwatch("Apricot", 255, 224, 178),
                PaletteSwatch("Pistachio", 220, 237, 200),
                PaletteSwatch("Periwinkle", 197, 202, 233),
            ]
        case .cosmic:
            [
                PaletteSwatch("Space", 10, 8, 35),
                PaletteSwatch("Nebula", 103, 58, 183),
                PaletteSwatch("Ultraviolet", 98, 0, 234),
                PaletteSwatch("Laser Pink", 255, 23, 125),
                PaletteSwatch("Meteor", 255, 109, 0),
                PaletteSwatch("Star", 255, 238, 88),
                PaletteSwatch("Alien Mint", 29, 233, 182),
                PaletteSwatch("Orbit Blue", 41, 121, 255),
            ]
        }
    }
}
