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
            .fullScreenCover(item: $task) { PlantReminderTaskView(plantID: $0.plantID) }
            .fullScreenCover(item: $planTask) { PlanTaskFlowView(taskID: $0.id) }
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
                            .font(BloomType.title).fixedSize(horizontal: false, vertical: true)
                        Text("Get to know your plants, one small check at a time.").font(BloomType.body).foregroundStyle(BloomTheme.secondary)
                    }
                    HStack(alignment: .top, spacing: 10) {
                        welcomeStep("Observe", symbol: "eye")
                        welcomeStep("Decide", symbol: "leaf")
                        welcomeStep("Remember", symbol: "book.closed")
                    }
                    Text("Waiting counts, too. Care happens at your plant's pace.").font(BloomType.supporting).foregroundStyle(BloomTheme.secondary)
                }.padding(24)
            }.background(BloomTheme.canvas).bloomFooter {
                VStack(spacing: 8) {
                    Button { if store.start(sample: false) { addFirstPlant() } } label: { BloomActionLabel(title: "Add my first plant") }.buttonStyle(BloomPrimaryButtonStyle())
                    Button("Explore a sample garden") { _ = store.start(sample: true) }.font(BloomType.section).frame(minHeight: 44)
                }
            }
        }
    }
    private func welcomeStep(_ title: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            BloomIconTile(symbol: symbol)
            Text(title).font(BloomType.supporting.weight(.semibold))
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
                            Text("My plants (\(store.garden.plants.count))").bloomHeading().accessibilityIdentifier("home-plant-count")
                            Spacer(minLength: 8)
                            NavigationLink("See all", value: PlantsRoute.all).font(BloomType.section)
                        }.padding(.horizontal, 20)
                        if dynamicTypeSize.isAccessibilitySize {
                            VStack(spacing: 13) {
                                ForEach(Array(store.garden.plants.prefix(2))) { plant in plantLink(plant) }
                            }.padding(.horizontal, 20)
                        } else {
                            ScrollView(.horizontal) {
                                LazyHStack(alignment: .top, spacing: 13) {
                                    ForEach(store.garden.plants) { plant in
                                        plantLink(plant).containerRelativeFrame(.horizontal, count: 2, spacing: 13)
                                    }
                                }.scrollTargetLayout()
                            }.padding(.horizontal, 20)
                                .scrollTargetBehavior(.viewAligned).scrollIndicators(.hidden)
                                .accessibilityIdentifier("home-plant-carousel")
                        }
                    }
                }
                HomeCareFeed(selection: $care).padding(.horizontal, 20)
            }.padding(.top, 16).padding(.bottom, 28)
                .animation(reduceMotion ? nil : BloomTheme.spring, value: store.garden.plants.count)
        }.background(BloomTheme.canvas).accessibilityIdentifier("home-scroll")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) { brandHeader }
            .fullScreenCover(isPresented: $settings) { PreferencesView() }
            .safeAreaInset(edge: .bottom, spacing: 0) { CareFeedbackBanner() }
    }
    private func plantLink(_ plant: Plant) -> some View {
        NavigationLink(value: PlantsRoute.plant(plant.id)) {
            BloomPlantCard(plant: plant, status: store.latestCheck(for: plant.id)?.soil?.rawValue ?? "Not checked yet")
        }.buttonStyle(BloomPressStyle()).accessibilityIdentifier("plant-\(plant.name)")
    }
    private var brandHeader: some View {
        HStack(spacing: 11) {
            Button { settings = true } label: {
                HStack(spacing: 10) {
                    BloomMark()
                    Text("Bloom").font(BloomType.title).foregroundStyle(BloomTheme.ink)
                }.frame(minHeight: 44).contentShape(Rectangle())
            }.buttonStyle(BloomPressStyle()).accessibilityElement(children: .ignore)
                .accessibilityLabel("Bloom, preferences and settings").accessibilityAddTraits(.isButton)
                .accessibilityIdentifier("home-preferences")
            Spacer(minLength: 8)
            BloomAddPlantButton(action: presentPlantAdd).accessibilityIdentifier("home-add-plant")
        }.padding(.horizontal, 20).padding(.vertical, 12)
            .background(.regularMaterial)
            .overlay(alignment: .bottom) { Rectangle().fill(BloomTheme.border.opacity(0.55)).frame(height: 0.5) }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("fixed-home-header")
    }
    private var emptyGarden: some View {
        VStack(spacing: 20) {
            Image("area-whole").resizable().scaledToFill().frame(width: 140, height: 140).clipShape(RoundedRectangle(cornerRadius: 20)).accessibilityHidden(true)
            Text("A little room to grow.").font(BloomType.title).multilineTextAlignment(.center)
            Text("Bring your first plant into Bloom.\nWe'll take it one check at a time.")
                .font(BloomType.body).foregroundStyle(BloomTheme.secondary).multilineTextAlignment(.center)
            Button(action: presentPlantAdd) { BloomActionLabel(title: "Add a plant") }.buttonStyle(BloomPrimaryButtonStyle()).accessibilityIdentifier("empty-add-plant")
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
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .top), count: typeSize.isAccessibilitySize ? 1 : 2), spacing: 14) {
                ForEach(plants) { plant in
                    NavigationLink(value: PlantsRoute.plant(plant.id)) { BloomPlantCard(plant: plant, status: store.latestCheck(for: plant.id)?.soil?.rawValue ?? "Not checked yet") }
                        .buttonStyle(.plain).accessibilityIdentifier("all-plant-\(plant.name)")
                }
            }.padding(20)
        }.background(BloomTheme.canvas).toolbar(.visible, for: .navigationBar).navigationTitle("My plants").navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search your plants")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    BloomAddPlantButton(action: addPlant).accessibilityIdentifier("collection-add-plant")
                }
            }
    }
}

struct PlantDetailView: View {
    @Environment(BloomStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let plantID: UUID
    @State private var checking = false
    @State private var observing = false
    @State private var careTask: PlanTaskRoute?
    @State private var careGuidance: CareGuidanceDestination?
    @State private var editing = false
    @State private var deleting = false
    private var openPlans: [CarePlan] { store.plans(for: plantID).filter { store.planIsOpen($0.id) } }
    var body: some View {
        Group {
            if let plant = store.plant(plantID) {
                List {
                    Section {
                        PlantPortrait(plant: plant, contentMode: .fill).frame(height: 230)
                            .listRowInsets(EdgeInsets()).listRowBackground(Color.clear).listRowSeparator(.hidden)
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(plant.name).font(BloomTheme.heading).foregroundStyle(BloomTheme.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                                if !plant.species.isEmpty {
                                    Text(plant.species).font(BloomType.body).italic().foregroundStyle(BloomTheme.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }.frame(maxWidth: .infinity, alignment: .leading)
                                .accessibilityElement(children: .combine).accessibilityAddTraits(.isHeader)
                                .accessibilityIdentifier("plant-detail-identity")
                            let check = store.latestCheck(for: plantID)
                            let lastWatered = store.wateredDate(for: plant)
                            if check != nil || lastWatered != nil {
                                PlantStatusSummary(check: check, lastWatered: lastWatered).accessibilityIdentifier("plant-last-care-summary")
                            }
                        }.padding(.vertical, 4).frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Section("Care") {
                        Button { checking = true } label: { BloomActionRow(title: "Check soil") }.accessibilityIdentifier("start-check")
                        Button { observing = true } label: { BloomActionRow(title: "Record a change") }.accessibilityIdentifier("start-observation")
                        ReminderCard(plantID: plantID, compact: true)
                    }
                    if !openPlans.isEmpty {
                        Section("Care plans") {
                            ForEach(openPlans) { plan in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(plan.baseline.observation).font(BloomType.section).foregroundStyle(BloomTheme.ink)
                                    if plan.status == .needsReview {
                                        Button { careGuidance = CareGuidanceDestination(id: plan.observationID) } label: {
                                            BloomActionRow(title: "Review care steps")
                                        }.buttonStyle(.plain).accessibilityIdentifier("plant-review-care")
                                    }
                                    if let next = store.tasks(for: plan.id).first(where: { $0.status == .pending && $0.step != .review })
                                        ?? store.tasks(for: plan.id).first(where: { $0.status == .pending && $0.step == .review }) {
                                        Button { careTask = PlanTaskRoute(id: next.id) } label: {
                                            VStack(alignment: .leading, spacing: 4) {
                                                BloomActionRow(title: next.step == .review ? "Check progress" : next.step.title)
                                                if let due = next.due {
                                                    Text(due.formatted(date: .abbreviated, time: .omitted)).font(BloomType.supporting).foregroundStyle(BloomTheme.secondary)
                                                }
                                            }.contentShape(Rectangle())
                                        }.buttonStyle(.plain).accessibilityIdentifier("plant-next-care-task")
                                    }
                                }.padding(.vertical, 4)
                                NavigationLink { CarePlanDetailView(planID: plan.id) } label: { BloomActionRow(title: "View care plan") }
                                    .accessibilityIdentifier("plant-care-plan-\(plan.id.uuidString)")
                            }
                        }
                    }
                    Section("Additional details") {
                        LabeledContent("Plant type", value: plant.plantTypeName)
                            .accessibilityElement(children: .combine).accessibilityIdentifier("plant-detail-type")
                        LabeledContent("Location", value: plant.location.isEmpty ? "Not set" : plant.location)
                            .accessibilityElement(children: .ignore).accessibilityLabel("Location")
                            .accessibilityValue(plant.location.isEmpty ? "Not set" : plant.location)
                            .accessibilityIdentifier("plant-detail-location")
                        LabeledContent("Placement", value: plant.placement?.rawValue ?? "Not set")
                        LabeledContent("Initial condition", value: plant.initialStatus?.rawValue ?? "Not set")
                        LabeledContent("Light", value: plant.light)
                        LabeledContent("Drainage holes", value: plant.drainage)
                    }
                    if store.plans(for: plantID).contains(where: { !store.planIsOpen($0.id) }) {
                        Section("Past care plans") {
                            ForEach(store.plans(for: plantID).filter { !store.planIsOpen($0.id) }) { plan in
                                NavigationLink { CarePlanDetailView(planID: plan.id) } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(plan.baseline.observation)
                                        Text(plan.status.rawValue).font(BloomType.supporting).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    Section {
                        if store.records(for: plantID).isEmpty { Text("Your first check will begin this plant's story.").foregroundStyle(.secondary) }
                        ForEach(store.records(for: plantID).prefix(3)) { record in
                            NavigationLink { RecordDetailView(recordID: record.id) } label: { RecordRow(record: record, plantName: plant.name) }
                        }
                    } header: {
                        HStack {
                            Text("Recent activity")
                            Spacer()
                            NavigationLink("See all") { HistoryView(initialPlantID: plantID) }
                                .font(BloomType.body).textCase(nil).accessibilityIdentifier("plant-all-activity")
                        }
                    }
                    if let reference = plant.referenceURL {
                        Section { Link("About this species on Wikipedia", destination: reference) }
                    }
                }.listStyle(.insetGrouped).bloomNativeForm().toolbar(.visible, for: .navigationBar).navigationTitle("Plant").navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Menu {
                                Button("Edit plant", systemImage: "pencil") { editing = true }
                                Button("Remove plant", systemImage: "trash", role: .destructive) { deleting = true }
                            } label: { BloomSymbol(name: "ellipsis") }.accessibilityLabel("Plant options")
                        }
                    }
                    .fullScreenCover(isPresented: $checking) { CareCheckView(plantID: plantID) }
                    .fullScreenCover(isPresented: $observing) { ObservationFlowView(plantID: plantID) }
                    .fullScreenCover(item: $careTask) { PlanTaskFlowView(taskID: $0.id) }
                    .fullScreenCover(item: $careGuidance) { item in CareGuidanceFlow(observationID: item.id, replacing: store.plan(for: item.id)?.id) }
                    .safeAreaInset(edge: .bottom, spacing: 0) { CareFeedbackBanner(plantID: plantID) }
                    .fullScreenCover(isPresented: $editing) { PlantEditorView(plant: plant, isNew: false) }
                    .alert("Remove \(plant.name)?", isPresented: $deleting) {
                        Button("Cancel", role: .cancel) { }
                        Button("Remove", role: .destructive) {
                            if store.deletePlant(plantID) {
                                store.careFeedback = CareFlowFeedback(plantID: plantID, title: "\(plant.name) removed", detail: "Removed from My plants.")
                                dismiss()
                            }
                        }
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
    private let originalTypeName: String
    var finish: (() -> Void)? = nil
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoError: String?
    @State private var viewingPhoto = false
    @State private var photoLoading = false
    init(plant: Plant, isNew: Bool, finish: (() -> Void)? = nil) {
        _plant = State(initialValue: plant)
        self.isNew = isNew
        self.originalTypeName = plant.plantTypeName
        self.finish = finish
    }
    var valid: Bool { !plant.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !photoLoading }
    var body: some View {
        Group {
            if isNew { form } else { NavigationStack { form } }
        }
    }
    private var form: some View {
        Form {
            Section {
                Button { viewingPhoto = true } label: {
                    PlantPortrait(plant: plant).frame(height: 200).clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(alignment: .bottomTrailing) {
                            Text("View photo").font(BloomType.supporting.weight(.semibold))
                                .padding(10).background(.regularMaterial, in: Capsule()).padding(12)
                        }
                }.buttonStyle(.plain).accessibilityLabel("View or change plant photo").accessibilityIdentifier("edit-plant-photo")
                    .listRowInsets(EdgeInsets()).listRowSeparator(.hidden)
                if let photoError { Text(photoError).foregroundStyle(.red).font(BloomType.supporting) }
            }
            Section("Basic details") {
                LabeledContent("Plant type", value: originalTypeName)
                    .accessibilityElement(children: .combine).accessibilityIdentifier("plant-type-value")
                LabeledContent("Nickname") {
                    TextField("", text: $plant.name).multilineTextAlignment(.trailing)
                        .textInputAutocapitalization(.words).accessibilityIdentifier("plant-name-field")
                }
            }
            Section {
                Picker("Placement", selection: $plant.placement) { Text("Not set").tag(PlantPlacement?.none); ForEach(PlantPlacement.allCases) { Text($0.rawValue).tag(Optional($0)) } }
                Picker("Light", selection: $plant.light) { ForEach(["Not sure", "Direct light", "Indirect light", "Low light"], id: \.self) { Text($0) } }
                Picker("Drainage holes", selection: $plant.drainage) { ForEach(["Not sure", "Yes", "No"], id: \.self) { Text($0) } }
            } header: { Text("Additional details") }
        }.scrollContentBackground(.hidden).background(BloomTheme.canvas)
            .navigationTitle(isNew ? "Make it yours" : "Edit plant").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isNew { ToolbarItem(placement: .cancellationAction) { Button("Cancel", systemImage: "xmark") { dismiss() }.labelStyle(.iconOnly) } }
            }
            .bloomNativeFooter { BloomPrimaryAction(title: isNew ? "Add plant" : "Save changes", action: save).disabled(!valid).accessibilityIdentifier("save-plant") }
            .fullScreenCover(isPresented: $viewingPhoto) {
                NavigationStack {
                    VStack(spacing: 16) {
                        PlantPortrait(plant: plant, contentMode: .fit).frame(maxWidth: .infinity, maxHeight: .infinity)
                        if photoLoading { ProgressView("Opening photo…") }
                        if let photoError { Text(photoError).font(BloomType.supporting).foregroundStyle(.red) }
                        PhotosPicker(selection: $selectedPhoto, matching: .images) { Text("Change photo").frame(maxWidth: .infinity) }
                            .buttonStyle(BloomPrimaryButtonStyle()).disabled(photoLoading).accessibilityIdentifier("change-plant-photo")
                        if plant.photo != nil {
                            Button("Use original photo") { plant.photo = nil; selectedPhoto = nil; photoError = nil }
                                .frame(minHeight: 44).disabled(photoLoading)
                        }
                    }.padding(20).background(BloomTheme.canvas)
                        .navigationTitle("Plant photo").navigationBarTitleDisplayMode(.inline)
                        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Close photo") { viewingPhoto = false } } }
                }
            }
            .onChange(of: selectedPhoto) { _, photo in
                guard let photo else { return }
                photoLoading = true
                Task {
                    do {
                        guard let data = try await photo.loadTransferable(type: Data.self), let image = UIImage(data: data), let compressed = image.preparingThumbnail(of: CGSize(width: 1200, height: 1200))?.jpegData(compressionQuality: 0.8) else { throw CocoaError(.fileReadCorruptFile) }
                        plant.photo = compressed; photoError = nil
                    } catch { photoError = "This photo couldn't be opened. Please choose another." }
                    photoLoading = false; selectedPhoto = nil
                }
            }
    }
    private func save() {
        plant.name = plant.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let saved: Bool
        if isNew {
            plant.typeName = originalTypeName
            saved = store.savePlant(plant)
        } else { saved = store.updatePlantDetails(plant) }
        if saved { BloomFeedback.success(); if let finish { finish() } else { dismiss() } }
    }
}
