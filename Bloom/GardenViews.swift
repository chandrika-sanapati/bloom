import SwiftUI
import PhotosUI
import UserNotifications

enum PlantsRoute: Hashable { case all, plant(UUID), search, activity }
private enum PlantDetailDestination: Hashable {
    case carePlan(UUID)
    case record(UUID)
    case activity(UUID)
}

private func plantAccessibilityIdentifier(_ plant: Plant, in plants: [Plant], prefix: String) -> String {
    let matching = plants.filter { $0.displayName == plant.displayName }
    guard matching.count > 1 else { return "\(prefix)\(plant.displayName)" }
    let location = plant.location.isEmpty ? "Plant" : plant.location.replacingOccurrences(of: " ", with: "-")
    return "\(prefix)\(plant.displayName)-\(location)"
}

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
                            AddPlantFlowView(navigate: { plantsPath.append($0) }, completed: { _ in
                                plantsPath = NavigationPath()
                            })
                        }
                    }
                }.navigationLinkIndicatorVisibility(.hidden)
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
        Group {
            if store.garden.plants.isEmpty {
                GeometryReader { geometry in
                    ScrollView {
                        emptyGarden.padding(.horizontal, BloomSpacing.large)
                            .frame(maxWidth: .infinity, minHeight: geometry.size.height, alignment: .center)
                            .offset(y: -32)
                    }.background(BloomTheme.canvas).accessibilityIdentifier("home-scroll")
                }
            } else {
                let showsNextCardPeek = store.garden.plants.count > 2
                ScrollView {
                    VStack(alignment: .leading, spacing: BloomSpacing.large) {
                    VStack(alignment: .leading, spacing: BloomSpacing.medium) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("My plants (\(store.garden.plants.count))").bloomHeading().accessibilityIdentifier("home-plant-count")
                            Spacer(minLength: 8)
                            NavigationLink("See all", value: PlantsRoute.all).font(BloomType.section)
                        }.padding(.horizontal, BloomSpacing.large)
                        if dynamicTypeSize.isAccessibilitySize {
                            VStack(spacing: BloomSpacing.medium) {
                                ForEach(Array(store.garden.plants.prefix(2))) { plant in plantLink(plant) }
                            }.padding(.horizontal, BloomSpacing.large)
                        } else {
                            ScrollView(.horizontal) {
                                LazyHStack(alignment: .top, spacing: BloomSpacing.medium) {
                                    ForEach(store.garden.plants) { plant in
                                        plantLink(plant).containerRelativeFrame(.horizontal) { length, _ in
                                            showsNextCardPeek ? (length - BloomSpacing.medium) * 0.44 : (length - BloomSpacing.medium) / 2
                                        }
                                    }
                                }.scrollTargetLayout()
                            }.padding(.horizontal, BloomSpacing.large)
                                .scrollTargetBehavior(.viewAligned).scrollIndicators(.hidden)
                                .accessibilityIdentifier("home-plant-carousel")
                        }
                    }
                    HomeCareFeed(selection: $care).padding(.horizontal, BloomSpacing.large)
                    }.padding(.top, BloomSpacing.medium).padding(.bottom, BloomSpacing.large)
                        .animation(reduceMotion ? nil : BloomTheme.spring, value: store.garden.plants.count)
                }.background(BloomTheme.canvas).accessibilityIdentifier("home-scroll")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) { brandHeader }
            .fullScreenCover(isPresented: $settings) { PreferencesView() }
            .safeAreaInset(edge: .bottom, spacing: 0) { CareFeedbackBanner() }
    }
    private func plantLink(_ plant: Plant) -> some View {
        NavigationLink(value: PlantsRoute.plant(plant.id)) {
            BloomPlantCard(plant: plant, status: store.latestCheck(for: plant.id)?.soil?.rawValue ?? "Not checked yet")
        }.buttonStyle(BloomPressStyle()).accessibilityIdentifier(plantAccessibilityIdentifier(plant, in: store.garden.plants, prefix: "plant-"))
    }
    private var brandHeader: some View {
        HStack(spacing: BloomSpacing.small) {
            Button { settings = true } label: {
                HStack(spacing: BloomSpacing.small) {
                    BloomMark()
                    Text("Bloom").font(BloomType.title).foregroundStyle(BloomTheme.ink)
                }.frame(minHeight: 44).contentShape(Rectangle())
            }.buttonStyle(BloomPressStyle()).accessibilityElement(children: .ignore)
                .accessibilityLabel("Bloom, preferences and settings").accessibilityAddTraits(.isButton)
                .accessibilityIdentifier("home-preferences")
            Spacer(minLength: 8)
            if !store.garden.plants.isEmpty {
                BloomAddPlantButton(action: presentPlantAdd).accessibilityIdentifier("home-add-plant")
            }
        }.padding(.horizontal, BloomSpacing.large).padding(.vertical, BloomSpacing.medium)
            .background(.regularMaterial)
            .overlay(alignment: .bottom) { Rectangle().fill(BloomTheme.border.opacity(0.55)).frame(height: 0.5) }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("fixed-home-header")
    }
    private var emptyGarden: some View {
        VStack(spacing: BloomSpacing.large) {
            Image("area-whole").resizable().scaledToFill().frame(width: 144, height: 144)
                .clipShape(RoundedRectangle(cornerRadius: BloomTheme.cardRadius, style: .continuous)).accessibilityHidden(true)
            Button(action: presentPlantAdd) { BloomActionLabel(title: "Add plant") }.buttonStyle(BloomPrimaryButtonStyle()).accessibilityIdentifier("empty-add-plant")
        }.padding(BloomSpacing.large).frame(maxWidth: .infinity)
            .background(BloomTheme.surface, in: RoundedRectangle(cornerRadius: BloomTheme.cardRadius, style: .continuous))
    }
}

struct AllPlantsView: View {
    @Environment(BloomStore.self) private var store
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.presentPlantAdd) private var addPlant
    @State private var query = ""
    private var plants: [Plant] { store.garden.plants.filter { query.isEmpty || [$0.displayName, $0.species, $0.location].contains { $0.localizedCaseInsensitiveContains(query) } } }
    var body: some View {
        ScrollView {
            if plants.isEmpty { ContentUnavailableView.search(text: query).padding(.top, 40) }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .top), count: typeSize.isAccessibilitySize ? 1 : 2), spacing: 16) {
                ForEach(plants) { plant in
                    NavigationLink(value: PlantsRoute.plant(plant.id)) { BloomPlantCard(plant: plant, status: store.latestCheck(for: plant.id)?.soil?.rawValue ?? "Not checked yet") }
                        .buttonStyle(.plain).accessibilityIdentifier(plantAccessibilityIdentifier(plant, in: store.garden.plants, prefix: "all-plant-"))
                }
            }.padding(BloomSpacing.medium)
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
    @State private var detailDestination: PlantDetailDestination?
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
                        VStack(alignment: .leading, spacing: BloomSpacing.medium) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(plant.displayName).font(BloomTheme.heading).foregroundStyle(BloomTheme.ink)
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
                            PlantStatusSummary(check: check, lastWatered: lastWatered).accessibilityIdentifier("plant-last-care-summary")
                        }.padding(.vertical, 4).frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Section("Care") {
                        Button { checking = true } label: { BloomActionRow(title: "Check soil") }.accessibilityIdentifier("start-check")
                        Button { observing = true } label: { BloomActionRow(title: "Record a change") }.accessibilityIdentifier("start-observation")
                        ReminderCard(plantID: plantID, compact: true)
                    }
                    let pastPlans = store.plans(for: plantID).filter { !store.planIsOpen($0.id) }
                    if !openPlans.isEmpty || !pastPlans.isEmpty {
                        Section("Care plans") {
                            ForEach(openPlans) { plan in
                                let next = store.tasks(for: plan.id).first(where: { $0.status == .pending && $0.step != .review })
                                    ?? store.tasks(for: plan.id).first(where: { $0.status == .pending && $0.step == .review })
                                VStack(alignment: .leading, spacing: BloomSpacing.medium) {
                                    Text(plan.baseline.observation).font(BloomType.section).foregroundStyle(BloomTheme.ink)
                                        .fixedSize(horizontal: false, vertical: true)
                                    if plan.status == .needsReview {
                                        Button { careGuidance = CareGuidanceDestination(id: plan.observationID) } label: {
                                            BloomActionRow(title: "Review care steps")
                                        }.buttonStyle(.plain).accessibilityIdentifier("plant-review-care")
                                     } else if let next {
                                         Button { careTask = PlanTaskRoute(id: next.id) } label: {
                                             VStack(alignment: .leading, spacing: BloomSpacing.small) {
                                                Text("Next action").font(BloomType.supporting).foregroundStyle(BloomTheme.secondary)
                                                BloomActionRow(title: next.step == .review ? "Check progress" : next.step.title)
                                            }.contentShape(Rectangle())
                                        }.buttonStyle(.plain).accessibilityIdentifier("plant-next-care-task")
                                        if let due = next.due {
                                            BloomDatedStatusRow(title: "Due", value: due.formatted(date: .abbreviated, time: .omitted),
                                                                accessibilityValue: due.formatted(date: .complete, time: .shortened))
                                        }
                                    }
                                    Divider()
                                    Button { openCarePlan(plan.id) } label: {
                                        BloomActionRow(title: "Care plan details")
                                    }.buttonStyle(.plain).accessibilityIdentifier("plant-care-plan-\(plan.id.uuidString)")
                                 }.padding(BloomSpacing.medium).frame(maxWidth: .infinity, alignment: .leading)
                                    .background(BloomTheme.surface, in: RoundedRectangle(cornerRadius: BloomTheme.cardRadius, style: .continuous))
                            }
                            ForEach(pastPlans) { plan in
                                Button { openCarePlan(plan.id) } label: {
                                    HStack(spacing: BloomSpacing.medium) {
                                        VStack(alignment: .leading, spacing: BloomSpacing.small) {
                                            Text(plan.baseline.observation).font(BloomType.section).foregroundStyle(BloomTheme.ink)
                                            StatusTag(text: plan.status.rawValue, tone: plan.status == .resolved ? .teal : .neutral)
                                        }
                                        Spacer(minLength: 8)
                                        BloomSymbol(name: "chevron.right", compact: true).foregroundStyle(BloomTheme.teal)
                                    }.padding(BloomSpacing.medium).frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                                        .background(BloomTheme.surface, in: RoundedRectangle(cornerRadius: BloomTheme.cardRadius, style: .continuous))
                                }.buttonStyle(.plain).accessibilityIdentifier("past-care-plan-\(plan.id.uuidString)")
                            }
                        }
                    }
                    let hasKnownPlantDetails = !plant.location.isEmpty || plant.placement != nil || plant.initialStatus != nil || plant.light != "Not set" || plant.drainage != "Not set"
                    if hasKnownPlantDetails {
                        Section("Plant details") {
                            if !plant.location.isEmpty {
                                LabeledContent("Location", value: plant.location)
                                    .accessibilityElement(children: .ignore).accessibilityLabel("Location")
                                    .accessibilityValue(plant.location)
                                    .accessibilityIdentifier("plant-detail-location")
                            }
                            if let placement = plant.placement { LabeledContent("Placement", value: placement.rawValue) }
                            if let initialStatus = plant.initialStatus { LabeledContent("First impression", value: initialStatus.rawValue) }
                            if plant.light != "Not set" { LabeledContent("Light", value: plant.light) }
                            if plant.drainage != "Not set" { LabeledContent("Drainage holes", value: plant.drainage) }
                        }
                    }
                    let recentRecords = store.records(for: plantID)
                    if !recentRecords.isEmpty {
                        Section {
                            ForEach(recentRecords.prefix(3)) { record in
                                Button { detailDestination = .record(record.id) } label: {
                                    HStack(spacing: BloomSpacing.small) {
                                        RecordRow(record: record, plantName: plant.displayName)
                                        BloomSymbol(name: "chevron.right", compact: true).foregroundStyle(BloomTheme.teal)
                                    }.contentShape(Rectangle())
                                }.buttonStyle(.plain)
                                    .accessibilityIdentifier("plant-recent-activity-\(record.id.uuidString)")
                            }
                        } header: {
                            HStack {
                                Text("Recent activity")
                                Spacer()
                                Button("See all") { detailDestination = .activity(plantID) }
                                    .font(BloomType.body).textCase(nil).accessibilityIdentifier("plant-all-activity")
                            }
                        }
                    }
                    if let reference = plant.referenceURL {
                        Section {
                            Link("Learn more", destination: reference)
                                .accessibilityHint("Opens Wikipedia")
                        }
                    }
                }.listStyle(.insetGrouped).bloomNativeForm().navigationLinkIndicatorVisibility(.hidden)
                    .toolbar(.visible, for: .navigationBar).navigationTitle("Plant").navigationBarTitleDisplayMode(.inline)
                    .navigationDestination(item: $detailDestination) { destination in
                        switch destination {
                        case .carePlan(let id): CarePlanDetailView(planID: id)
                        case .record(let id): RecordDetailView(recordID: id)
                        case .activity(let id): HistoryView(initialPlantID: id)
                        }
                    }
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
                    .fullScreenCover(isPresented: $editing) { PlantEditorView(plant: plant) }
                    .alert("Remove \(plant.displayName)?", isPresented: $deleting) {
                        Button("Cancel", role: .cancel) { }
                        Button("Remove", role: .destructive) {
                            if store.deletePlant(plantID) {
                                store.careFeedback = CareFlowFeedback(plantID: plantID, title: "\(plant.displayName) removed", detail: "Removed from My plants.", autoDismiss: true)
                                dismiss()
                            }
                        }
                    } message: { Text("This removes this plant's photos, history, reminders and care plans.") }
            } else { ContentUnavailableView("Plant removed", systemImage: "leaf") }
        }
    }
    private func openCarePlan(_ id: UUID) {
        detailDestination = .carePlan(id)
    }
}

struct PlantEditorView: View {
    @Environment(BloomStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State var plant: Plant
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoError: String?
    @State private var viewingPhoto = false
    @State private var photoLoading = false
    init(plant: Plant) {
        _plant = State(initialValue: plant)
    }
    var valid: Bool { !photoLoading }
    var body: some View {
        NavigationStack { form }
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
            Section("Plant") {
                LabeledContent("Plant type", value: plant.displayName)
                    .accessibilityElement(children: .combine).accessibilityIdentifier("plant-type-value")
            }
            Section("Where it lives") {
                Picker("Placement", selection: $plant.placement) {
                    Text("Not set").tag(PlantPlacement?.none)
                    ForEach(PlantPlacement.allCases) { Text($0.rawValue).tag(Optional($0)) }
                }.pickerStyle(.segmented).accessibilityIdentifier("edit-plant-placement")
                    .onChange(of: plant.placement) { oldValue, newValue in
                        if oldValue != newValue,
                           (oldValue == .indoor ? PlantRoom.indoor : PlantRoom.outdoor).contains(where: { $0.name == plant.location }) {
                            plant.location = ""
                        }
                    }
                TextField("Room or location", text: $plant.location)
                    .textInputAutocapitalization(.words).bloomInput().accessibilityIdentifier("edit-plant-location")
                if let placement = plant.placement {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 105), spacing: 8)], spacing: 8) {
                        ForEach(placement == .indoor ? PlantRoom.indoor : PlantRoom.outdoor) { room in
                            let selected = plant.location == room.name
                            Button {
                                plant.location = selected ? "" : room.name
                                BloomFeedback.selection()
                            } label: {
                                Text(room.name).font(BloomType.supporting)
                                    .foregroundStyle(selected ? BloomTheme.ink : BloomTheme.teal)
                                    .frame(maxWidth: .infinity, minHeight: 44).padding(.horizontal, 8)
                                    .background(selected ? BloomTheme.selected : BloomTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(selected ? BloomTheme.teal : BloomTheme.border))
                            }.buttonStyle(.plain).accessibilityIdentifier("edit-plant-room-\(room.name)")
                                .accessibilityAddTraits(selected ? .isSelected : [])
                        }
                    }
                }
            }
            Section("Plant care details") {
                Picker("Initial condition", selection: $plant.initialStatus) {
                    Text("Not set").tag(InitialPlantStatus?.none)
                    ForEach(InitialPlantStatus.allCases) { Text($0.rawValue).tag(Optional($0)) }
                }.accessibilityIdentifier("edit-plant-initial-condition")
                Picker("Light", selection: $plant.light) {
                    ForEach(["Not set", "Not sure", "Direct light", "Indirect light", "Low light"], id: \.self) { Text($0) }
                }.accessibilityIdentifier("edit-plant-light")
                Picker("Drainage holes", selection: $plant.drainage) {
                    ForEach(["Not set", "Not sure", "Yes", "No"], id: \.self) { Text($0) }
                }.accessibilityIdentifier("edit-plant-drainage")
            }
        }.scrollContentBackground(.hidden).background(BloomTheme.canvas)
            .navigationTitle("Edit plant").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel", systemImage: "xmark") { dismiss() }.labelStyle(.iconOnly) }
            }
            .bloomNativeFooter { BloomPrimaryAction(title: "Save changes", action: save).disabled(!valid).accessibilityIdentifier("save-plant") }
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
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button("Close photo", systemImage: "xmark") { viewingPhoto = false }.labelStyle(.iconOnly)
                            }
                        }
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
        if store.updatePlantDetails(plant) { BloomFeedback.success(); dismiss() }
    }
}
