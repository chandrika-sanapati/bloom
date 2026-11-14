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
        WateringHomeView()
    }
}
