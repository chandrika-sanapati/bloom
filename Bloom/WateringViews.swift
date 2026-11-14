import SwiftUI

struct WateringHomeView: View {
    @Environment(BloomStore.self) private var store
    @State private var showingCatalog = false
    @State private var showingSettings = false
    @State private var selectedTab = HomeTab.upcoming
    @State private var taskPlantID: UUID?

    enum HomeTab: String, CaseIterable, Identifiable {
        case upcoming = "Upcoming"
        case past = "Past"
        var id: Self { self }
    }

    private var scheduledPlants: [(Plant, WateringSchedule)] {
        store.garden.plants.compactMap { plant in
            guard let schedule = store.schedule(plant.id) else { return nil }
            return (plant, schedule)
        }.sorted { $0.1.nextCheckAt < $1.1.nextCheckAt }
    }

    private var pastRecords: [WateringRecord] { Array(store.garden.wateringRecords.sorted { $0.recordedAt > $1.recordedAt }.prefix(5)) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                if store.garden.plants.isEmpty {
                    emptyState
                } else {
                    List {
                        Section { plantsSection }
                        Section { activitySection }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationBarHidden(true)
            .overlay(alignment: .bottomTrailing) {
                Button { showingCatalog = true } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .frame(width: 56, height: 56)
                        .background(.tint, in: Circle())
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                }
                .accessibilityLabel("Add plant")
                .accessibilityIdentifier("home-add-plant")
                .padding(20)
            }
            .sheet(isPresented: $showingCatalog) { PlantCatalogView() }
            .sheet(isPresented: $showingSettings) { NotificationSettingsView() }
            .fullScreenCover(item: taskRoute) { WateringCheckView(plantID: $0.id) }
        }
    }

    private var taskRoute: Binding<WateringRoute?> {
        Binding(get: { taskPlantID.map(WateringRoute.init(id:)) }, set: { taskPlantID = $0?.id })
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("Bloom").font(.largeTitle.bold())
            Spacer(minLength: 0)
            Button { showingSettings = true } label: {
                Image(systemName: "bell")
                    .font(.headline.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .foregroundStyle(.tint)
            }
            .accessibilityLabel("Notification settings")
            .accessibilityIdentifier("home-notification-settings")
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 16) {
            Color.clear
                .frame(height: 200)
                .overlay {
                    Image("area-whole").resizable().scaledToFill()
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 6) {
                Text("Add your first plant").font(.title3.bold())
                Text("Tap + to choose a supported plant and start its watering check-ins.")
                    .font(.body).foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var plantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My plants").font(.title3.bold())
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(store.garden.plants) { plant in
                        NavigationLink { PlantWateringDetailView(plantID: plant.id) } label: {
                            PlantSummaryCard(plant: plant, schedule: store.schedule(plant.id))
                        }.buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity").font(.title3.bold())
            Picker("Activity", selection: $selectedTab) {
                ForEach(HomeTab.allCases) { Text($0.rawValue).tag($0) }
            }.pickerStyle(.segmented).accessibilityLabel("Activity view")
            if selectedTab == .upcoming { upcoming } else { past }
        }
    }

    private var upcoming: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(CareTaskTiming.allCases) { timing in
                let items = scheduledPlants.filter { CareTaskTiming.classify($0.1.nextCheckAt) == timing }
                if !items.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        if timing != .upcoming { Text(timing.rawValue).font(.headline) }
                        ForEach(items, id: \.0.id) { item in
                            Button { taskPlantID = item.0.id } label: {
                                WateringTaskRow(plant: item.0, schedule: item.1, timing: timing)
                            }.buttonStyle(.plain)
                        }
                    }
                }
            }
            if scheduledPlants.isEmpty {
                EmptyActivityCard(title: "Nothing scheduled", detail: "Add a supported plant to start watering check-ins.")
            }
        }
    }

    private var past: some View {
        VStack(alignment: .leading, spacing: 8) {
            if pastRecords.isEmpty {
                EmptyActivityCard(title: "No watering history yet", detail: "Your completed checks will appear here.")
            } else {
                ForEach(pastRecords) { record in
                    if let plant = store.plant(record.plantID) {
                        WateringHistoryRow(plant: plant, record: record)
                    }
                }
            }
        }
    }
}

struct WateringRoute: Identifiable { let id: UUID }

private struct PlantSummaryCard: View {
    let plant: Plant
    let schedule: WateringSchedule?
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(plant.asset).resizable().scaledToFill().frame(width: 150, height: 110).clipped()
            Text(plant.displayName).font(.headline)
            if let schedule { Text("Check \(schedule.nextCheckAt, format: .dateTime.month().day())").font(.caption).foregroundStyle(.secondary) }
            else { Text("Schedule unavailable").font(.caption).foregroundStyle(.secondary) }
        }
        .frame(width: 150, alignment: .leading)
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct WateringTaskRow: View {
    let plant: Plant
    let schedule: WateringSchedule
    let timing: CareTaskTiming
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: timing == .overdue ? "exclamationmark.circle.fill" : "drop.fill")
                .foregroundStyle(timing == .overdue ? .orange : .blue)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text("Check watering").font(.headline)
                Text(plant.displayName).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Text(schedule.nextCheckAt, format: .dateTime.month().day())
                .font(.subheadline.weight(.semibold)).foregroundStyle(timing == .overdue ? .orange : .secondary)
            Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Check watering for \(plant.displayName), \(timing.rawValue)")
    }
}

private struct WateringHistoryRow: View {
    let plant: Plant
    let record: WateringRecord
    var body: some View {
        HStack {
            Image(systemName: record.outcome == .watered ? "drop.fill" : "eye.fill")
                .foregroundStyle(record.outcome == .watered ? .blue : .secondary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(record.outcome.rawValue).font(.headline)
                Text(plant.displayName).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Text(record.recordedAt, format: .dateTime.month().day()).font(.subheadline).foregroundStyle(.secondary)
        }
        .padding(.vertical, 10)
    }
}

private struct EmptyActivityCard: View {
    let title: String
    let detail: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            Text(detail).font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct PlantCatalogView: View {
    @Environment(BloomStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSpecies: PlantSpecies?

    var body: some View {
        NavigationStack {
            List(PlantSpecies.catalog) { species in
                Button {
                    selectedSpecies = species
                } label: {
                    HStack(spacing: 14) {
                        Image(species.asset).resizable().scaledToFill().frame(width: 64, height: 64).clipped().clipShape(RoundedRectangle(cornerRadius: 12))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(species.name).font(.headline)
                            Text(species.scientific).font(.subheadline.italic()).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Add a plant")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .sheet(item: $selectedSpecies) { species in
                PlantSetupView(species: species)
            }
        }
    }
}

private struct PlantSetupView: View {
    @Environment(BloomStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let species: PlantSpecies
    @State private var knowsLastWatered = false
    @State private var lastWatered = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(species.name).font(.title2.bold())
                    Text(species.scientific).font(.subheadline.italic()).foregroundStyle(.secondary)
                    Text("Bloom will suggest when to check the soil. You decide whether the plant needs water.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Section("Last watered") {
                    Toggle("I know the last watered date", isOn: $knowsLastWatered)
                    if knowsLastWatered {
                        DatePicker("Date", selection: $lastWatered, in: ...Date(), displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Add \(species.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let plant = Plant(name: species.name, species: species.scientific, asset: species.asset)
                        _ = store.addPlant(plant, lastWatered: knowsLastWatered ? lastWatered : nil)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PlantWateringDetailView: View {
    @Environment(BloomStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let plantID: UUID
    @State private var check = false
    @State private var editingDate = false
    @State private var nextDate = Date()

    var body: some View {
        if let plant = store.plant(plantID), let schedule = store.schedule(plantID) {
            List {
                Section {
                    Image(plant.asset).resizable().scaledToFill().frame(height: 220).clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    Text(plant.displayName).font(.title.bold())
                    Text(plant.species).font(.subheadline.italic()).foregroundStyle(.secondary)
                }
                Section("Watering") {
                    LabeledContent("Next check", value: schedule.nextCheckAt.formatted(date: .abbreviated, time: .shortened))
                    LabeledContent("Starting suggestion", value: "Every \(schedule.profileIntervalDays) days")
                    if let lastWatered = store.lastWatered(for: plantID) {
                        LabeledContent("Last watered", value: lastWatered.formatted(date: .abbreviated, time: .omitted))
                    } else {
                        LabeledContent("Last watered", value: "Not recorded")
                    }
                    Button("Check watering") { check = true }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                }
                Section {
                    Button("Edit next check") { nextDate = schedule.nextCheckAt; editingDate = true }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Plant")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $check) { WateringCheckView(plantID: plantID) }
            .sheet(isPresented: $editingDate) {
                NavigationStack {
                    DatePicker("Next check", selection: $nextDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.graphical).padding()
                        .navigationTitle("Edit next check")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { editingDate = false } }
                            ToolbarItem(placement: .confirmationAction) { Button("Save") { _ = store.editNextCheck(for: plantID, date: nextDate); editingDate = false } }
                        }
                }
            }
        } else {
            ContentUnavailableView("Plant unavailable", systemImage: "leaf")
        }
    }
}

struct WateringCheckView: View {
    @Environment(BloomStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let plantID: UUID
    @State private var outcome: WateringOutcome?
    @State private var soil: Soil = .unknown
    @State private var dateEditing = false
    @State private var date = Date()
    @State private var error: String?

    var body: some View {
        NavigationStack {
            if let plant = store.plant(plantID), let schedule = store.schedule(plantID) {
                Form {
                    Section {
                        Text(plant.displayName).font(.title2.bold())
                        if let profile = store.wateringProfile(for: plant) {
                            Text(profile.careCue).font(.subheadline).foregroundStyle(.secondary)
                        }
                        LabeledContent("Scheduled check", value: schedule.nextCheckAt.formatted(date: .abbreviated, time: .shortened))
                    }
                    Section("What did you find?") {
                        Picker("Soil", selection: $soil) { ForEach(Soil.allCases) { Text($0.rawValue).tag($0) } }
                    }
                    Section("What did you do?") {
                        ForEach(WateringOutcome.allCases) { value in
                            Button { outcome = value } label: {
                                HStack {
                                    Text(value.rawValue)
                                    Spacer()
                                    if outcome == value { Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint) }
                                }
                            }.foregroundStyle(.primary)
                        }
                    }
                    Section { Button("Edit next check") { date = schedule.nextCheckAt; dateEditing = true } }
                    if let error { Section { Text(error).foregroundStyle(.red) } }
                }
                .navigationTitle("Check watering")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
                .safeAreaInset(edge: .bottom) {
                    Button("Save check") { save() }
                        .buttonStyle(.borderedProminent)
                        .disabled(outcome == nil)
                        .frame(maxWidth: .infinity).padding()
                        .background(.bar)
                }
                .sheet(isPresented: $dateEditing) {
                    NavigationStack {
                        DatePicker("Next check", selection: $date, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.graphical).padding()
                            .navigationTitle("Edit next check")
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dateEditing = false } }
                                ToolbarItem(placement: .confirmationAction) { Button("Save") { _ = store.editNextCheck(for: plantID, date: date); dateEditing = false } }
                            }
                    }
                }
            } else { ContentUnavailableView("Watering task unavailable", systemImage: "drop") }
        }
    }

    private func save() {
        guard let outcome else { error = "Choose what you did."; return }
        let followUp = outcome == .checkedNotWatered && soil == .dry ? WateringFollowUp.defaultDays : nil
        guard store.completeWateringCheck(for: plantID, outcome: outcome, soil: soil, followUpDays: followUp) != nil else {
            error = "Your check couldn't be saved. Please try again."
            return
        }
        dismiss()
    }
}

private struct NotificationSettingsView: View {
    @Environment(BloomStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var busy = false
    @State private var message: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Watering notifications", isOn: Binding(
                        get: { store.garden.appPreferences.taskNotifications },
                        set: update
                    ))
                    Text("Bloom only reminds you about future checks. Overdue tasks never create a notification burst.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                if let message { Section { Text(message).foregroundStyle(.secondary) } }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .overlay { if busy { ProgressView().controlSize(.large) } }
        }
    }

    private func update(_ enabled: Bool) {
        busy = true
        Task {
            message = await store.setTaskNotifications(enabled)
            busy = false
        }
    }
}
