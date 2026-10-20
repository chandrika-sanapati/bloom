import SwiftUI

struct BloomPrimaryAction: View {
    let title: String
    var symbol = "arrow.right"
    let action: () -> Void
    var body: some View {
        Button(action: action) { Label(title, systemImage: symbol).frame(maxWidth: .infinity) }
            .buttonStyle(.borderedProminent).controlSize(.large).buttonBorderShape(.roundedRectangle(radius: 16))
    }
}

extension View {
    func bloomNativeForm() -> some View { scrollContentBackground(.hidden).background(BloomTheme.canvas) }
    func bloomNativeFooter<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        safeAreaInset(edge: .bottom) { content().padding(.horizontal, 20).padding(.vertical, 12).background(.bar) }
    }
}

struct BloomPlantIdentity: View {
    let plant: Plant
    var body: some View {
        HStack(spacing: 12) {
            PlantPortrait(plant: plant, contentMode: .fit).frame(width: 48, height: 58).clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text(plant.name).font(.headline)
                Text(plant.location.isEmpty ? "Your plant" : plant.location).font(.subheadline).foregroundStyle(.secondary)
            }
        }.accessibilityElement(children: .combine)
    }
}
