import SwiftUI

@main
struct BloomApp: App {
    @State private var store = BloomStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
        }
    }
}

struct RootView: View {
    @Environment(BloomStore.self) private var store

    var body: some View {
        Group {
            if store.garden.hasStarted {
                ContentUnavailableView("Watering MVP coming next", systemImage: "drop")
            } else {
                VStack(spacing: 16) {
                    Text("Bloom").font(.largeTitle.bold())
                    Text("A focused watering assistant for four common houseplants.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    Button("Start Bloom") { _ = store.start() }
                        .buttonStyle(.borderedProminent)
                }
                .padding(32)
            }
        }
    }
}
