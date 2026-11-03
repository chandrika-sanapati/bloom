import SwiftUI

enum CareFeedSelection: String, CaseIterable, Identifiable {
    case tasks = "Upcoming", activity = "Past"
    var id: Self { self }
}

private enum HomeCareTask: Identifiable {
    case reminder(Plant), plan(PlanTask)
    var id: String { switch self { case .reminder(let p): "reminder-\(p.id)"; case .plan(let t): "plan-\(t.id)" } }
    var due: Date { switch self { case .reminder(let p): p.reminder!; case .plan(let t): t.due! } }
}

struct HomeCareFeed: View {
    @Environment(BloomStore.self) private var store
    @Binding var selection: CareFeedSelection
    @State private var task: PlantTaskRoute?
    @State private var planTask: PlanTaskRoute?
    private var tasks: [HomeCareTask] {
        (store.garden.plants.filter { $0.reminder != nil }.map(HomeCareTask.reminder) + store.openPlanTasks.map(HomeCareTask.plan)).sorted { $0.due < $1.due }
    }
    private var activity: [CareRecord] { store.garden.records.sorted { $0.date > $1.date } }

    var body: some View {
        VStack(alignment: .leading, spacing: BloomSpacing.medium) {
            Text("Activity").bloomHeading().accessibilityAddTraits(.isHeader)
            Picker("Activity", selection: $selection) {
                ForEach(CareFeedSelection.allCases) { Text($0.rawValue).tag($0) }
            }.pickerStyle(.segmented).accessibilityIdentifier("home-care-picker")
            if selection == .tasks {
                ForEach(store.carePlans.filter { $0.status == .needsReview }) { plan in
                    NavigationLink { CarePlanDetailView(planID: plan.id).toolbar(.visible, for: .navigationBar) } label: {
                        HStack(spacing: BloomSpacing.medium) {
                            BloomIconTile(symbol: "magnifyingglass", tone: .yellow)
                            VStack(alignment: .leading, spacing: BloomSpacing.small) {
                                Text("Needs review").font(BloomType.section).foregroundStyle(BloomTheme.ink)
                                Text(store.plant(plan.plantID)?.displayName ?? "Your plant")
                                    .font(BloomType.supporting).foregroundStyle(BloomTheme.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                            BloomSymbol(name: "chevron.right", compact: true).foregroundStyle(BloomTheme.teal)
                        }.bloomCard(padding: BloomSpacing.medium).contentShape(RoundedRectangle(cornerRadius: BloomTheme.cardRadius, style: .continuous))
                    }.buttonStyle(.plain).accessibilityElement(children: .combine)
                }
                if tasks.isEmpty {
                    InfoCard(title: "Nothing scheduled", icon: "calendar", tone: .neutral)
                } else {
                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        VStack(alignment: .leading, spacing: BloomSpacing.medium) {
                            ForEach(CareTaskTiming.allCases) { timing in
                                let scheduled = tasks.filter { CareTaskTiming.classify($0.due, now: context.date) == timing }
                                if !scheduled.isEmpty {
                                    if timing != .upcoming {
                                        Text(timing.rawValue).font(BloomType.section).foregroundStyle(BloomTheme.secondary).accessibilityAddTraits(.isHeader)
                                    }
                                    ForEach(scheduled) { item in
                                        switch item {
                                        case .reminder(let plant):
                                            Button { task = PlantTaskRoute(plantID: plant.id) } label: { BloomReminderRow(plant: plant) }
                                                .buttonStyle(.plain).accessibilityIdentifier("reminder-task-\(plant.id.uuidString)")
                                        case .plan(let item):
                                            Button { planTask = PlanTaskRoute(id: item.id) } label: { HomePlanTaskRow(task: item) }
                                                .buttonStyle(.plain).accessibilityIdentifier("care-plan-task-\(item.id.uuidString)")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                if activity.isEmpty {
                    InfoCard(title: "No activity yet", icon: "clock.arrow.circlepath", tone: .neutral)
                } else {
                    ForEach(activity.prefix(5)) { record in
                        NavigationLink {
                            RecordDetailView(recordID: record.id).toolbar(.visible, for: .navigationBar)
                        } label: {
                            HStack(alignment: .center, spacing: BloomSpacing.small) {
                                RecordRow(record: record, plantName: store.plant(record.plantID)?.displayName ?? "Plant")
                                Spacer(minLength: 0)
                                BloomSymbol(name: "chevron.right", compact: true).foregroundStyle(BloomTheme.teal).accessibilityHidden(true)
                            }.bloomCard(padding: BloomSpacing.medium)
                        }.buttonStyle(.plain).accessibilityIdentifier("home-activity-\(record.id.uuidString)")
                    }
                    NavigationLink("See all", value: PlantsRoute.activity)
                        .font(BloomType.section).frame(minHeight: 44)
                        .accessibilityIdentifier("home-all-activity")
                }
            }
        }
        .fullScreenCover(item: $task) { PlantReminderTaskView(plantID: $0.plantID) }
        .fullScreenCover(item: $planTask) { PlanTaskFlowView(taskID: $0.id) }
    }
}

struct HomePlanTaskRow: View {
    @Environment(BloomStore.self) private var store
    @Environment(\.dynamicTypeSize) private var typeSize
    let task: PlanTask
    var body: some View {
        VStack(alignment: .leading, spacing: BloomSpacing.small) {
            HStack(alignment: .center, spacing: BloomSpacing.small) {
                VStack(alignment: .leading, spacing: BloomSpacing.small) {
                    Text(task.step.title).font(BloomType.section).fixedSize(horizontal: false, vertical: true)
                    Text((store.plant(task.plantID)?.displayName ?? "Your plant") + (task.due.map { " · " + $0.formatted(date: .abbreviated, time: .omitted) } ?? ""))
                        .font(BloomType.supporting).foregroundStyle(BloomTheme.secondary)
                }.frame(maxWidth: .infinity, alignment: .leading)
                if !typeSize.isAccessibilitySize {
                    StatusTag(text: task.step == .review ? "Review" : "Care plan", tone: task.step == .review ? .yellow : .blue)
                    BloomSymbol(name: "chevron.right", compact: true).foregroundStyle(BloomTheme.teal)
                }
            }
            if typeSize.isAccessibilitySize {
                HStack(alignment: .center, spacing: BloomSpacing.small) {
                    StatusTag(text: task.step == .review ? "Review" : "Care plan", tone: task.step == .review ? .yellow : .blue)
                    Spacer(minLength: BloomSpacing.small)
                    BloomSymbol(name: "chevron.right", compact: true).foregroundStyle(BloomTheme.teal)
                }
            }
        }.bloomCard(padding: BloomSpacing.medium).accessibilityElement(children: .combine)
    }
}
