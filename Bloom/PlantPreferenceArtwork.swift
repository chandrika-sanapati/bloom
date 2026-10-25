import SwiftUI

/// Reference photography shows the plant form without inventing a species illustration.
struct PlantFormArtwork: View {
    let form: PlantFormPreference
    private var asset: String {
        switch form { case .upright: "snake"; case .bushy: "rubber"; case .trailing: "pothos"; case .climbing: "monstera" }
    }
    var body: some View {
        GeometryReader { geometry in
            Image(asset).resizable().scaledToFill().frame(width: geometry.size.width, height: geometry.size.height).clipped()
        }.clipShape(RoundedRectangle(cornerRadius: 10)).accessibilityHidden(true)
    }
}

struct IndoorLightArtwork: View {
    let light: IndoorSearchLight
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12).fill(light == .bright ? BloomTone.yellow.surface : BloomTone.blue.surface)
            RoundedRectangle(cornerRadius: 4).stroke(BloomTheme.teal.opacity(0.4), lineWidth: 2).frame(width: 39, height: 44).offset(x: -10, y: -3)
            Rectangle().fill(BloomTheme.teal.opacity(0.3)).frame(width: 2, height: 44).offset(x: -10, y: -3)
            Rectangle().fill(BloomTheme.teal.opacity(0.3)).frame(width: 39, height: 2).offset(x: -10, y: -3)
            if light == .bright {
                Image(systemName: "sun.max.fill").foregroundStyle(BloomTone.yellow.ink).font(.title3).offset(x: 17, y: -18)
            } else if light == .lower {
                RoundedRectangle(cornerRadius: 3).fill(BloomTone.blue.accent.opacity(0.35)).frame(width: 23, height: 48).offset(x: -20, y: -3)
            } else {
                Image(systemName: "questionmark.circle.fill").symbolRenderingMode(.palette).foregroundStyle(BloomTheme.teal, .white).font(.title2).offset(x: 20, y: -18)
            }
            PlantFormArtwork(form: .upright).frame(width: 40, height: 40).offset(x: 17, y: 18)
        }.frame(width: 80, height: 80).accessibilityHidden(true)
    }
}
