import SwiftUI
import PhotosUI
import UserNotifications

enum PlantsRoute: Hashable { case all, plant(UUID), search, activity }

struct PlantTaskRoute: Identifiable { let plantID: UUID; var id: UUID { plantID } }

struct RootView: View {
    @Environment(BloomStore.self) private var store
    @State private var plantsPath = NavigationPath()
    @State private var task: PlantTaskRoute?
    @State private var planTask: PlanTaskRoute?
    @State private var notifications = BloomNotificationRouter.shared
    var body: some View {
        Group {
            if store.garden.hasStarted {
                NavigationStack(path: $plantsPath) {
                    GardenView().navigationDestination(for: PlantsRoute.self) { route in
                        switch route {
                        case .all: AllPlantsView()
                        case .plant(let id): PlantDetailView(plantID: id)
                        case .activity: HistoryView().toolbar(.visible, for: .navigationBar)
                        case .search:
                            AddPlantFlowView(navigate: { plantsPath.append($0) }, completed: { id in
                                plantsPath = NavigationPath([PlantsRoute.plant(id)])
                            })
                        }
                    }
                }
            } else { WelcomeView(addFirstPlant: openPlantSearch) }
        }
            .environment(\.returnToPlants, { plantsPath = NavigationPath() })
            .environment(\.presentPlantAdd, openPlantSearch)
            .sheet(item: $task) { PlantReminderTaskView(plantID: $0.plantID) }
            .sheet(item: $planTask) { PlanTaskFlowView(taskID: $0.id) }
            .onChange(of: notifications.planTaskID) { _, _ in openNotification() }
            .onChange(of: notifications.plantID) { _, _ in openNotification() }
            .onAppear { openNotification(); store.refreshPlanTaskNotifications() }
    }
    private func openPlantSearch() {
        plantsPath.append(PlantsRoute.search)
    }
    private func openNotification() {
        if let id = notifications.planTaskID {
            notifications.planTaskID = nil
            if store.careTask(id) != nil { plantsPath = NavigationPath(); planTask = PlanTaskRoute(id: id) }
            return
        }
        guard let id = notifications.plantID else { return }
        notifications.plantID = nil
        if store.plant(id) != nil { plantsPath = NavigationPath(); task = PlantTaskRoute(plantID: id) }
    }
}

struct WelcomeView: View {
    @Environment(BloomStore.self) private var store
    var addFirstPlant: () -> Void
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(spacing: 10) { BloomMark(); Text("Bloom").font(BloomTheme.heading); Spacer() }
                    PlantPortrait(plant: Plant(name: "Snake Plant", species: "", asset: "snake"))
                        .frame(height: 265).clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Good things grow with a little attention.")
                            .font(.system(.largeTitle, design: .rounded).weight(.bold)).fixedSize(horizontal: false, vertical: true)
                        Text("Get to know your plants, one small check at a time.").font(.body).foregroundStyle(BloomTheme.secondary)
                    }
                    HStack(alignment: .top, spacing: 10) {
                        welcomeStep("Observe", symbol: "eye")
                        welcomeStep("Decide", symbol: "leaf")
                        welcomeStep("Remember", symbol: "book.closed")
                    }
                    Text("Waiting counts, too. Care happens at your plant's pace.").font(.footnote).foregroundStyle(BloomTheme.secondary)
                }.padding(24)
            }.background(BloomTheme.canvas).bloomFooter {
                VStack(spacing: 8) {
                    Button { if store.start(sample: false) { addFirstPlant() } } label: { BloomActionLabel(title: "Add my first plant", symbol: "plus") }.buttonStyle(.borderedProminent).controlSize(.large)
                    Button("Explore a sample garden") { _ = store.start(sample: true) }.font(.subheadline.weight(.semibold)).frame(minHeight: 44)
                }
            }
        }
    }
    private func welcomeStep(_ title: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            BloomIconTile(symbol: symbol)
            Text(title).font(.caption.weight(.semibold))
        }.frame(maxWidth: .infinity, alignment: .leading).padding(12)
            .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct GardenView: View {
    @Environment(BloomStore.self) private var store
    @Environment(\.presentPlantAdd) private var presentPlantAdd
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var settings = false
    @State private var care = CareFeedSelection.tasks
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if store.garden.plants.isEmpty {
                    emptyGarden.padding(.horizontal, 20)
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("My plants (\(store.garden.plants.count))").font(BloomTheme.section).accessibilityIdentifier("home-plant-count")
                            Spacer(minLength: 8)
                            NavigationLink("See all", value: PlantsRoute.all).font(.subheadline.weight(.semibold))
                        }.padding(.horizontal, 20)
                        ScrollView(.horizontal) {
                            LazyHStack(alignment: .top, spacing: 13) {
                                ForEach(store.garden.plants) { plant in
                                    NavigationLink(value: PlantsRoute.plant(plant.id)) {
                                        BloomPlantCard(plant: plant, status: store.latestCheck(for: plant.id)?.soil?.rawValue ?? "Not checked yet")
                                            .containerRelativeFrame(.horizontal) { width, _ in
                                                min(width * (dynamicTypeSize.isAccessibilitySize ? 0.82 : 0.40), dynamicTypeSize.isAccessibilitySize ? 360 : 220)
                                            }
                                    }.buttonStyle(BloomPressStyle()).accessibilityIdentifier("plant-\(plant.name)")
                                }
                            }.scrollTargetLayout()
                        }.contentMargins(.horizontal, 20, for: .scrollContent)
                            .scrollTargetBehavior(.viewAligned).scrollIndicators(.hidden)
                            .accessibilityIdentifier("home-plant-carousel")
                        Button(action: presentPlantAdd) {
                            Label("Add plant", systemImage: "plus").frame(maxWidth: .infinity, minHeight: 28)
                        }.buttonStyle(.bordered).controlSize(.regular).tint(BloomTheme.teal)
                            .accessibilityHint("Search for a plant to add to your collection")
                            .accessibilityIdentifier("home-add-plant").padding(.horizontal, 20)
                    }
                }
                HomeCareFeed(selection: $care).padding(.horizontal, 20)
                if store.garden.isSample {
                    Text("Sample garden · Tasks and activities are examples. Notifications start only when you set a reminder.")
                        .font(.caption).foregroundStyle(BloomTheme.secondary).padding(.horizontal, 20)
                }
            }.padding(.top, 16).padding(.bottom, 28)
                .animation(reduceMotion ? nil : BloomTheme.spring, value: store.garden.plants.count)
        }.background(BloomTheme.canvas).accessibilityIdentifier("home-scroll")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) { brandHeader }
            .sheet(isPresented: $settings) { PreferencesView() }
    }
    private var brandHeader: some View {
        HStack(spacing: 11) {
            BloomMark()
            Text("Bloom").font(BloomTheme.heading)
            Spacer(minLength: 8)
            if store.garden.isSample { StatusTag(text: "Sample", tone: .yellow) }
            Button { settings = true } label: {
                Image(systemName: "gearshape").font(.title3).frame(width: 44, height: 44).background(.white, in: Circle())
            }.buttonStyle(BloomPressStyle()).accessibilityLabel("Preferences")
                .accessibilityIdentifier("home-preferences")
        }.padding(.horizontal, 20).padding(.vertical, 12)
            .background(.regularMaterial)
            .overlay(alignment: .bottom) { Rectangle().fill(BloomTheme.border.opacity(0.55)).frame(height: 0.5) }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("fixed-home-header")
    }
    private var emptyGarden: some View {
        VStack(spacing: 20) {
            BloomIconTile(symbol: "leaf", emphasized: true).scaleEffect(1.3).padding(12)
            Text("A little room to grow.").font(.system(.title, design: .rounded).weight(.bold)).multilineTextAlignment(.center)
            Text("Bring your first plant into Bloom.\nWe'll take it one check at a time.")
                .font(.subheadline).foregroundStyle(BloomTheme.secondary).multilineTextAlignment(.center)
            Button(action: presentPlantAdd) { BloomActionLabel(title: "Add a plant", symbol: "plus") }.buttonStyle(.borderedProminent).controlSize(.large).accessibilityIdentifier("home-add-plant")
        }.padding(24).frame(maxWidth: .infinity).background(.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

struct AllPlantsView: View {
    @Environment(BloomStore.self) private var store
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.presentPlantAdd) private var addPlant
    @State private var query = ""
    private var plants: [Plant] { store.garden.plants.filter { query.isEmpty || [$0.name, $0.species, $0.location].contains { $0.localizedCaseInsensitiveContains(query) } } }
    var body: some View {
        ScrollView {
            if plants.isEmpty { ContentUnavailableView.search(text: query).padding(.top, 40) }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: typeSize.isAccessibilitySize ? 1 : 2), spacing: 14) {
                ForEach(plants) { plant in
                    NavigationLink(value: PlantsRoute.plant(plant.id)) { BloomPlantCard(plant: plant, status: store.latestCheck(for: plant.id)?.soil?.rawValue ?? "Not checked yet") }
                        .buttonStyle(.plain).accessibilityIdentifier("all-plant-\(plant.name)")
                }
            }.padding(20)
        }.background(BloomTheme.canvas).toolbar(.visible, for: .navigationBar).navigationTitle("My plants").navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search your plants")
            .toolbar { ToolbarItem(placement: .primaryAction) { Button("Add plant", systemImage: "plus", action: addPlant).labelStyle(.titleAndIcon) } }
    }
}

struct PlantDetailView: View {
    @Environment(BloomStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let plantID: UUID
    @State private var checking = false
    @State private var observing = false
    @State private var editing = false
    @State private var deleting = false
    var body: some View {
        Group {
            if let plant = store.plant(plantID) {
                List {
                    Section {
                        PlantPortrait(plant: plant, contentMode: .fit).frame(height: 230).listRowInsets(EdgeInsets()).listRowBackground(Color.clear)
                        if !plant.species.isEmpty { Text(plant.species).font(.subheadline).italic().foregroundStyle(.secondary) }
                    }
                    if !store.plans(for: plantID).isEmpty {
                        Section("Care plans") {
                            ForEach(store.plans(for: plantID)) { plan in
                                NavigationLink { CarePlanDetailView(planID: plan.id) } label: {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(plan.kind.title)
                                        Text(plan.status.rawValue).font(.caption).foregroundStyle(.secondary)
                                    }
                                }.accessibilityIdentifier("plant-care-plan-\(plan.id.uuidString)")
                            }
                        }
                    }
                    Section("Care") {
                        Button { checking = true } label: { Label("Check soil", systemImage: "drop") }.accessibilityIdentifier("start-check")
                        Button { observing = true } label: { Label("Record a change", systemImage: "eye") }.accessibilityIdentifier("start-observation")
                        if let check = store.latestCheck(for: plantID) { LabeledContent("Last check", value: check.summary).font(.subheadline) }
                    }
                    Section("Next check") { ReminderCard(plantID: plantID) }
                    Section("Its little corner") {
                        LabeledContent("Location", value: plant.location.isEmpty ? "Not set" : plant.location)
                        if let placement = plant.placement { LabeledContent("Placement", value: placement.rawValue) }
                        if let status = plant.initialStatus { LabeledContent("When added", value: status.rawValue) }
                        LabeledContent("Light", value: plant.light)
                        LabeledContent("Drainage holes", value: plant.drainage)
                        LabeledContent("Last watered", value: store.wateredDate(for: plant).map { $0.formatted(date: .abbreviated, time: .omitted) } ?? "Not sure")
                    }
                    Section("Recent activity") {
                        if store.records(for: plantID).isEmpty { Text("Your first check will begin this plant's story.").foregroundStyle(.secondary) }
                        ForEach(store.records(for: plantID).prefix(3)) { record in
                            NavigationLink { RecordDetailView(recordID: record.id) } label: { RecordRow(record: record, plantName: plant.name) }
                        }
                        NavigationLink { HistoryView(initialPlantID: plantID) } label: { Label("All plant activity", systemImage: "clock") }
                    }
                }.listStyle(.insetGrouped).bloomNativeForm().toolbar(.visible, for: .navigationBar).navigationTitle(plant.name).navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Menu {
                                Button("Edit plant", systemImage: "pencil") { editing = true }
                                Button("Remove plant", systemImage: "trash", role: .destructive) { deleting = true }
                            } label: { Image(systemName: "ellipsis") }.accessibilityLabel("Plant options")
                        }
                    }
                    .sheet(isPresented: $checking) { CareCheckView(plantID: plantID) }
                    .sheet(isPresented: $observing) { ObservationFlowView(plantID: plantID) }
                    .sheet(isPresented: $editing) { NavigationStack { PlantEditorView(plant: plant, isNew: false) } }
                    .confirmationDialog("Remove \(plant.name) and its records?", isPresented: $deleting, titleVisibility: .visible) {
                        Button("Remove plant", role: .destructive) { if store.deletePlant(plantID) { dismiss() } }
                    } message: { Text("This removes this plant's photos, history, reminders and care plans.") }
            } else { ContentUnavailableView("Plant removed", systemImage: "leaf") }
        }
    }
}

struct PlantEditorView: View {
    @Environment(BloomStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State var plant: Plant
    let isNew: Bool
    var finish: (() -> Void)? = nil
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoError: String?
    @State private var knowsWatering = false
    @State private var initialized = false
    @State private var watered = Date()
    @State private var photoLoading = false
    var valid: Bool { !plant.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !photoLoading }
    var body: some View {
        Group {
            if isNew { form } else { NavigationStack { form } }
        }
    }
    private var form: some View {
        Form {
            Section {
                PlantPortrait(plant: plant).frame(height: 220).clipShape(RoundedRectangle(cornerRadius: 18))
                    .listRowInsets(EdgeInsets()).listRowSeparator(.hidden)
                PhotosPicker(selection: $selectedPhoto, matching: .images) { Label(photoLoading ? "Loading photo…" : "Choose a plant photo", systemImage: "photo") }.disabled(photoLoading)
                if plant.photo != nil { Button("Use original portrait", role: .destructive) { plant.photo = nil; selectedPhoto = nil } }
                if let photoError { Text(photoError).foregroundStyle(.red).font(.caption) }
            }
            Section("The essentials") {
                TextField("Plant name", text: $plant.name).accessibilityIdentifier("plant-name-field")
                TextField("Species (optional)", text: $plant.species)
            }
            Section {
                TextField("Room or location", text: $plant.location)
                Picker("Placement", selection: $plant.placement) { Text("Not set").tag(PlantPlacement?.none); ForEach(PlantPlacement.allCases) { Text($0.rawValue).tag(Optional($0)) } }
                Picker("When added", selection: $plant.initialStatus) { Text("Not set").tag(InitialPlantStatus?.none); ForEach(InitialPlantStatus.allCases) { Text($0.rawValue).tag(Optional($0)) } }
                Picker("Light", selection: $plant.light) { ForEach(["Not sure", "Direct light", "Indirect light", "Low light"], id: \.self) { Text($0) } }
                Picker("Drainage holes", selection: $plant.drainage) { ForEach(["Not sure", "Yes", "No"], id: \.self) { Text($0) } }
                Toggle("I know when I last watered", isOn: $knowsWatering)
                if knowsWatering { DatePicker("Last watered", selection: $watered, in: ...Date(), displayedComponents: .date) }
            } header: { Text("A little context · Optional") } footer: { Text("Unknown is okay. You can update any detail later.") }
        }.scrollContentBackground(.hidden).background(BloomTheme.canvas)
            .navigationTitle(isNew ? "Make it yours" : "Edit plant").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isNew { ToolbarItem(placement: .cancellationAction) { Button("Close", systemImage: "xmark") { dismiss() }.labelStyle(.iconOnly) } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save plant", systemImage: "checkmark") { save() }.labelStyle(.iconOnly).disabled(!valid).accessibilityIdentifier("save-plant")
                }
            }
            .bloomNativeFooter { BloomPrimaryAction(title: isNew ? "Add to My Plants" : "Save changes", symbol: "checkmark", action: save).disabled(!valid) }
            .onAppear { guard !initialized else { return }; initialized = true; knowsWatering = plant.lastWatered != nil; watered = plant.lastWatered ?? Date() }
            .onChange(of: selectedPhoto) { _, photo in
                photoLoading = true
                Task {
                    do {
                        guard let data = try await photo?.loadTransferable(type: Data.self), let image = UIImage(data: data), let compressed = image.preparingThumbnail(of: CGSize(width: 1200, height: 1200))?.jpegData(compressionQuality: 0.8) else { throw CocoaError(.fileReadCorruptFile) }
                        plant.photo = compressed; photoError = nil
                    } catch { photoError = "This photo couldn't be opened. Please choose another." }
                    photoLoading = false
                }
            }
    }
    private func save() {
        plant.name = plant.name.trimmingCharacters(in: .whitespacesAndNewlines)
        plant.lastWatered = knowsWatering ? watered : nil
        if store.savePlant(plant) { BloomFeedback.success(); if let finish { finish() } else { dismiss() } }
    }
}
