import SwiftUI

enum CareFeedSelection: String, CaseIterable, Identifiable {
    case tasks = "Tasks", activity = "Activity"
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
        VStack(alignment: .leading, spacing: 16) {
            Text("Care").font(BloomTheme.section).accessibilityAddTraits(.isHeader)
            Picker("Care", selection: $selection) {
                ForEach(CareFeedSelection.allCases) { Text($0.rawValue).tag($0) }
            }.pickerStyle(.segmented).accessibilityIdentifier("home-care-picker")
            if selection == .tasks {
                ForEach(store.carePlans.filter { $0.status == .needsReview }) { plan in
                    NavigationLink { CarePlanDetailView(planID: plan.id).toolbar(.visible, for: .navigationBar) } label: {
                        InfoCard(title: "Review the plan · \(store.plant(plan.plantID)?.name ?? "Your plant")", message: "The result needs another look. Reassess before choosing more treatment.", icon: "magnifyingglass")
                    }.buttonStyle(.plain)
                }
                if tasks.isEmpty {
                    InfoCard(title: "No tasks scheduled", message: "Open a plant to check its soil or record a change. Set a reminder when you want to check back.", icon: "checkmark.circle")
                } else {
                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(CareTaskTiming.allCases) { timing in
                                let scheduled = tasks.filter { CareTaskTiming.classify($0.due, now: context.date) == timing }
                                if !scheduled.isEmpty {
                                    Text(timing.rawValue).font(.subheadline.weight(.medium)).foregroundStyle(BloomTheme.secondary).accessibilityAddTraits(.isHeader)
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
                    InfoCard(title: "Your care story starts here", message: "Saved checks, decisions, and observations will appear here. Waiting counts, too.", icon: "clock")
                } else {
                    ForEach(activity.prefix(5)) { record in
                        NavigationLink {
                            RecordDetailView(recordID: record.id).toolbar(.visible, for: .navigationBar)
                        } label: {
                            HStack(spacing: 10) {
                                RecordRow(record: record, plantName: store.plant(record.plantID)?.name ?? "Plant")
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(BloomTheme.teal).accessibilityHidden(true)
                            }.bloomCard(padding: 16)
                        }.buttonStyle(.plain).accessibilityIdentifier("home-activity-\(record.id.uuidString)")
                    }
                    NavigationLink("See all activity", value: PlantsRoute.activity)
                        .font(.subheadline.weight(.semibold)).frame(minHeight: 44)
                        .accessibilityIdentifier("home-all-activity")
                }
            }
        }
        .sheet(item: $task) { PlantReminderTaskView(plantID: $0.plantID) }
        .sheet(item: $planTask) { PlanTaskFlowView(taskID: $0.id) }
    }
}

struct HomePlanTaskRow: View {
    @Environment(BloomStore.self) private var store
    let task: PlanTask
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(store.plant(task.plantID)?.name ?? "Your plant").font(.subheadline.weight(.semibold))
                Spacer(minLength: 8)
                StatusTag(text: task.step == .review ? "Review" : "Action", tone: task.step == .review ? .yellow : .blue)
            }
            Text(task.step.title).font(.subheadline).fixedSize(horizontal: false, vertical: true)
            HStack {
                if let date = task.due { Text(date.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary) }
                Spacer()
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(BloomTheme.teal).accessibilityHidden(true)
            }
        }.bloomCard(padding: 16).accessibilityElement(children: .combine)
    }
}
