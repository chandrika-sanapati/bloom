import SwiftUI

struct PreferencesView: View {
    @Environment(BloomStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var reminderTime = false
    @State private var clearingSample = false
    @State private var notificationAccess = BloomNotificationAccess.notRequested

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TaskNotificationControls()
                    Button { reminderTime = true } label: {
                        preferenceRow("Default reminder time", subtitle: store.newReminderDate().formatted(date: .omitted, time: .shortened), chevron: true)
                    }.accessibilityIdentifier("preferences-reminder-time")
                } header: { Text("Care notifications") }
                Section("Data & privacy") {
                    NavigationLink { BloomDataPrivacyView() } label: {
                        BloomActionRow(title: "How your data is used")
                    }.accessibilityIdentifier("preferences-data")
                }
                Section("About Bloom") {
                    NavigationLink { BloomGuidanceAboutView() } label: {
                        BloomActionRow(title: "Care guidance & sources")
                    }.accessibilityIdentifier("preferences-guidance")
                    LabeledContent("App version", value: "\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0") (\(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"))")
                }
                if store.garden.isSample {
                    Section {
                        Button("Start fresh without sample plants", role: .destructive) { clearingSample = true }
                    }
                }
            }.bloomNativeForm().navigationLinkIndicatorVisibility(.hidden)
                .navigationTitle("Preferences").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close", systemImage: "xmark") { dismiss() }.labelStyle(.iconOnly).accessibilityIdentifier("close-preferences") } }
                .sheet(isPresented: $reminderTime) { DefaultReminderTimeView() }
                .confirmationDialog("Clear the sample garden?", isPresented: $clearingSample, titleVisibility: .visible) {
                    Button("Clear plants and records", role: .destructive) { if store.start(sample: false) { dismiss() } }
                } message: { Text("This also clears any plants and records you added while exploring the sample garden.") }
                .task { notificationAccess = await store.notificationClient.access() }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        Task { notificationAccess = await store.notificationClient.access() }
                    }
                }
                .onChange(of: store.appPreferences.taskNotifications) { _, _ in
                    Task { notificationAccess = await store.notificationClient.access() }
                }
        }
    }
    private func preferenceRow(_ title: String, subtitle: String, chevron: Bool = false) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).foregroundStyle(BloomTheme.ink)
                Text(subtitle).font(BloomType.supporting).foregroundStyle(BloomTheme.secondary).fixedSize(horizontal: false, vertical: true)
            }.frame(maxWidth: .infinity, alignment: .leading)
            if chevron { BloomSymbol(name: "chevron.right", compact: true).foregroundStyle(BloomTheme.secondary.opacity(0.6)).accessibilityHidden(true) }
        }.padding(.vertical, 3)
    }
}

struct TaskNotificationControls: View {
    @Environment(BloomStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @State private var access = BloomNotificationAccess.notRequested
    @State private var busy = false
    @State private var message: String?
    var body: some View {
        Group {
                Toggle("Task notifications", isOn: Binding(get: { store.appPreferences.taskNotifications && access == .allowed }, set: change))
                    .disabled(busy).accessibilityIdentifier("task-notifications-toggle")
                if busy { ProgressView("Updating notifications…") }
                if access == .denied {
                    Text("Notifications are off in iOS Settings.").font(BloomType.supporting).foregroundStyle(.secondary)
                    Button("Open iOS Settings") { openURL(URL(string: UIApplication.openSettingsURLString)!) }
                }
                if let message { Text(message).font(BloomType.body).foregroundStyle(.secondary).accessibilityIdentifier("notification-preference-message") }
        }
            .task { await refresh() }
            .onChange(of: scenePhase) { _, phase in if phase == .active { Task { await refresh() } } }
    }
    private func refresh() async { access = await store.notificationClient.access() }
    private func change(_ enabled: Bool) {
        busy = true; message = nil
        Task { message = await store.setTaskNotifications(enabled); await refresh(); busy = false }
    }
}

struct DefaultReminderTimeView: View {
    @Environment(BloomStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var time = Date()
    var body: some View {
        NavigationStack {
            Form {
                Section { DatePicker("Default reminder time", selection: $time, displayedComponents: .hourAndMinute).datePickerStyle(.wheel).labelsHidden().accessibilityIdentifier("default-reminder-time-picker") }
            }.bloomNativeForm().navigationTitle("Default reminder time").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel", systemImage: "xmark") { dismiss() }.labelStyle(.iconOnly) }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let parts = Calendar.current.dateComponents([.hour, .minute], from: time)
                            if store.setDefaultReminderTime(hour: parts.hour ?? 9, minute: parts.minute ?? 0) { dismiss() }
                        }.accessibilityIdentifier("save-default-reminder-time")
                    }
                }.onAppear { time = store.newReminderDate() }
        }
    }
}

struct BloomDataPrivacyView: View {
    var body: some View {
        Form {
            Section("On this device") {
                Text("Your plants, selected photos, observations, care plans, preferences, and recent searches are stored on this device. No account or cloud sync is used.")
                Text("Recent searches are limited to five. Clearing them doesn't remove your plants or care history.")
            }
            Section("Photos & notifications") {
                Text("Photos are chosen with the iOS photo picker; Bloom doesn't request camera or full-library access. Task alerts are scheduled on your device and can be turned off without removing tasks.")
            }
        }.bloomNativeForm().navigationTitle("Data & privacy").navigationBarTitleDisplayMode(.inline)
    }
}

struct BloomGuidanceAboutView: View {
    var body: some View {
        Form {
            Section("Observe, act, compare") {
                Text("Record a change, choose a first step and check progress. Bloom suggests possible causes, not a diagnosis. Photos help you compare changes.")
            }
            Section("Leaf changes") {
                Link("Helping a poorly houseplant · RHS", destination: URL(string: "https://www.rhs.org.uk/plants/types/houseplants/how-to-help-a-poorly-houseplant")!)
                Link("Leaf damage · RHS", destination: URL(string: "https://www.rhs.org.uk/prevention-protection/leaf-damage-on-houseplants")!)
            }
            Section("Pest guidance") {
                Link("Indoor plant insects · University of Minnesota", destination: URL(string: "https://extension.umn.edu/garden-and-home/yard-and-garden/yard-and-garden-insects/insects-on-indoor-plants")!)
            }
            Section("Photography") {
                Link("Pothos · Cindy Christian / NC State Extension", destination: URL(string: "https://plants.ces.ncsu.edu/plants/epipremnum-aureum/")!)
                Link("CC BY 4.0 · Cropped to fit the cards", destination: URL(string: "https://creativecommons.org/licenses/by/4.0/")!)
            }
        }.bloomNativeForm().navigationTitle("Care guidance & sources").navigationBarTitleDisplayMode(.inline)
    }
}
