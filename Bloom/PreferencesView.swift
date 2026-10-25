import SwiftUI
import CoreLocation

struct PreferencesView: View {
    @Environment(BloomStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var reminderTime = false
    @State private var clearingSearches = false
    @State private var clearingSample = false
    @State private var notificationAccess = BloomNotificationAccess.notRequested

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TaskNotificationControls()
                    Button { reminderTime = true } label: {
                        preferenceRow("Reminder time", subtitle: store.newReminderDate().formatted(date: .omitted, time: .shortened), chevron: true)
                    }.accessibilityIdentifier("preferences-reminder-time")
                } header: { Text("Care notifications") }
                Section("Data & privacy") {
                    Button { clearingSearches = true } label: {
                        preferenceRow("Clear recent searches", subtitle: store.recentPlantSearches.isEmpty ? "No recent searches" : "\(store.recentPlantSearches.count) recent searches")
                    }.disabled(store.recentPlantSearches.isEmpty).accessibilityIdentifier("preferences-clear-searches")
                    NavigationLink { BloomDataPrivacyView() } label: {
                        Text("How your data is used")
                    }.accessibilityIdentifier("preferences-data")
                }
                Section("About Bloom") {
                    NavigationLink { BloomGuidanceAboutView() } label: {
                        Text("Care guidance & sources")
                    }.accessibilityIdentifier("preferences-guidance")
                    LabeledContent("App version", value: "\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0") (\(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"))")
                }
                if store.garden.isSample {
                    Section {
                        Button("Start fresh without sample plants", role: .destructive) { clearingSample = true }
                    }
                }
            }.bloomNativeForm().navigationTitle("Preferences").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close", systemImage: "xmark") { dismiss() }.labelStyle(.iconOnly).accessibilityIdentifier("close-preferences") } }
                .sheet(isPresented: $reminderTime) { DefaultReminderTimeView() }
                .confirmationDialog("Clear recent searches?", isPresented: $clearingSearches, titleVisibility: .visible) {
                    Button("Clear searches", role: .destructive) { store.clearPlantSearches() }
                } message: { Text("Your plants, care records, and preferences will stay saved.") }
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

struct LocationAccessView: View {
    @Environment(BloomStore.self) private var store
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @State private var status = CLLocationManager().authorizationStatus
    @State private var editing = false
    var body: some View {
        Form {
            Section {
                LabeledContent("Device location", value: bloomLocationAccessLabel(status)).accessibilityIdentifier("location-access-status")
                Text("Bloom asks for location only when you tap Locate me. It uses your current city for discovery, without continuous tracking.")
                    .font(BloomType.body).foregroundStyle(.secondary)
                if status != .notDetermined {
                    Button("Open iOS Settings") { openURL(URL(string: UIApplication.openSettingsURLString)!) }
                }
            }
            Section("Saved area") {
                Text(store.plantSearchPreferences?.location?.displayName ?? store.plantSearchPreferences?.area.nonEmpty ?? "No city selected")
                    .accessibilityIdentifier("preferences-saved-area")
                Text("A saved city works even without device-location access. Changing iOS permission doesn't erase it.")
                    .font(BloomType.body).foregroundStyle(.secondary)
                Button("Choose city or use Locate me") { editing = true }
                    .accessibilityIdentifier("preferences-change-area")
            }
            Section {
                Text("Manage or remove your saved area in Your growing space. Removing it keeps your light and plant-type choices.")
                    .foregroundStyle(.secondary)
            }
        }.bloomNativeForm().navigationTitle("Location access").navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $editing) { PlantSearchPersonalizationView() }
            .onChange(of: scenePhase) { _, phase in if phase == .active { status = CLLocationManager().authorizationStatus } }
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
                Section { DatePicker("Reminder time", selection: $time, displayedComponents: .hourAndMinute).datePickerStyle(.wheel).labelsHidden().accessibilityIdentifier("default-reminder-time-picker") }
            }.bloomNativeForm().navigationTitle("Reminder time").navigationBarTitleDisplayMode(.inline)
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
            Section("Optional location") {
                Text("City search sends the city or postal code you enter to Open-Meteo / GeoNames. Locate me uses Apple's location and reverse-geocoding services only when requested.")
                Text("Only your selected city and approximate coordinates are saved. A coarser regional grid is sent to NASA POWER for monthly climate context. Saving a city does not enable background tracking or live weather.")
                Text("Turning off Personalized picks keeps your choices but stops using them for discovery. Remove saved area clears the city, coordinates, and cached regional climate after Save.")
                Link("City search · Open-Meteo", destination: URL(string: "https://open-meteo.com/en/docs/geocoding-api")!)
                Link("Regional climate · NASA POWER", destination: URL(string: "https://power.larc.nasa.gov/docs/services/api/temporal/climatology/")!)
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
            Section("Plant discovery") {
                Text("Picks use your indoor light, preferred plant shapes, and optional regional seasonal context. They don't measure local popularity or outdoor suitability.")
                Link("Indoor light · University of Minnesota", destination: URL(string: "https://extension.umn.edu/garden-and-home/yard-and-garden/gardening-in-minnesota/lighting-for-indoor-plants")!)
                Link("Houseplants · RHS", destination: URL(string: "https://www.rhs.org.uk/plants/types/houseplants/winter-interest-houseplants-care")!)
            }
            Section("Photography") {
                Link("Pothos · Cindy Christian / NC State Extension", destination: URL(string: "https://plants.ces.ncsu.edu/plants/epipremnum-aureum/")!)
                Link("CC BY 4.0 · Cropped to fit the cards", destination: URL(string: "https://creativecommons.org/licenses/by/4.0/")!)
            }
        }.bloomNativeForm().navigationTitle("Care guidance & sources").navigationBarTitleDisplayMode(.inline)
    }
}

private extension String { var nonEmpty: String? { isEmpty ? nil : self } }

private func bloomLocationAccessLabel(_ status: CLAuthorizationStatus) -> String {
    switch status {
    case .authorizedAlways, .authorizedWhenInUse: "Allowed by iOS"
    case .denied: "Off in iOS Settings"
    case .restricted: "Restricted by device settings"
    default: "Not requested"
    }
}
