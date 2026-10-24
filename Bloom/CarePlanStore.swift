import Foundation
import UserNotifications

extension BloomStore {
    var carePlans: [CarePlan] { garden.carePlans ?? [] }
    var careTasks: [PlanTask] { garden.careTasks ?? [] }
    func carePlan(_ id: UUID) -> CarePlan? { carePlans.first { $0.id == id } }
    func careTask(_ id: UUID) -> PlanTask? { careTasks.first { $0.id == id } }
    func plans(for plantID: UUID) -> [CarePlan] { carePlans.filter { $0.plantID == plantID }.sorted { $0.createdAt > $1.createdAt } }
    func plan(for observationID: UUID) -> CarePlan? { carePlans.filter { $0.observationID == observationID }.sorted { $0.createdAt > $1.createdAt }.first }
    func tasks(for planID: UUID) -> [PlanTask] { careTasks.filter { $0.planID == planID }.sorted { $0.position < $1.position } }
    func planIsOpen(_ id: UUID) -> Bool { carePlan(id).map { $0.status == .active || $0.status == .needsReview } ?? false }
    var openPlanTasks: [PlanTask] {
        careTasks.filter { $0.status == .pending && $0.due != nil && planIsOpen($0.planID) }
            .sorted { $0.due! < $1.due! }
    }
    func saveAssessment(_ answers: PestAssessment, observationID: UUID) -> Bool {
        guard var record = record(observationID), record.kind == .change else { return false }
        record.assessment = answers
        return saveRecord(record)
    }

    func saveLeafAssessment(_ answers: LeafAssessment, observationID: UUID) -> Bool {
        guard var record = record(observationID), record.kind == .change else { return false }
        record.leafAssessment = answers
        return saveRecord(record)
    }

    /// Accepting advice creates planned work, never a performed-care record.
    func startCarePlan(observationID: UUID, answers: PestAssessment, reviewDays: Int?, replacing: UUID? = nil, now: Date = .now) -> UUID? {
        guard answers.complete else { return nil }
        return createCarePlan(observationID: observationID, kind: answers.recommendation, pest: answers, leaf: nil, reviewDays: reviewDays, replacing: replacing, now: now)
    }
    func startLeafCarePlan(observationID: UUID, answers: LeafAssessment, reviewDays: Int?, replacing: UUID? = nil, now: Date = .now) -> UUID? {
        guard let observation = record(observationID), let plant = plant(observation.plantID) else { return nil }
        return createCarePlan(observationID: observationID, kind: answers.recommendation(for: observation, plant: plant), pest: nil, leaf: answers, reviewDays: reviewDays, replacing: replacing, now: now)
    }
    /// An accepted first-look task doesn't invent answers or identify a pest.
    func startPestInspectionPlan(observationID: UUID, reviewDays: Int?, replacing: UUID? = nil, now: Date = .now) -> UUID? {
        guard record(observationID)?.area == .pests else { return nil }
        return createCarePlan(observationID: observationID, kind: .inspection, pest: nil, leaf: nil, reviewDays: reviewDays, replacing: replacing, now: now)
    }
    private func createCarePlan(observationID: UUID, kind: CarePlanKind, pest: PestAssessment?, leaf: LeafAssessment?, reviewDays: Int?, replacing: UUID?, now: Date) -> UUID? {
        guard let baseline = record(observationID), baseline.kind == .change, plant(baseline.plantID) != nil,
              reviewDays == nil || (1...30).contains(reviewDays!) else { return nil }
        let existing = carePlans.first { $0.observationID == observationID && planIsOpen($0.id) }
        if let existing, replacing == nil { return existing.id }
        if let replacing { guard existing?.id == replacing else { return nil } }
        let plan = CarePlan(plantID: baseline.plantID, observationID: observationID, createdAt: now, kind: kind, assessment: pest, baseline: baseline, leafAssessment: leaf, reviewAfterDays: reviewDays, guidanceVersion: kind.isLeafGuidance ? "2026-10-24.1" : "2026-10-19.1")
        let actionDate = (Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: now)) ?? now.addingTimeInterval(86400)).addingTimeInterval(-1)
        var work = plan.kind.actionSteps.enumerated().map { index, step in
            PlanTask(plantID: plan.plantID, planID: plan.id, step: step, position: index, due: actionDate)
        }
        if reviewDays != nil { work.append(PlanTask(plantID: plan.plantID, planID: plan.id, step: .review, position: work.count, status: .waiting)) }
        guard commit({ garden in
            var plans = garden.carePlans ?? [], tasks = garden.careTasks ?? []
            if let replacing, let i = plans.firstIndex(where: { $0.id == replacing }) {
                plans[i].status = .stopped
                for index in tasks.indices where tasks[index].planID == replacing && tasks[index].isOpen { tasks[index].status = .cancelled }
            }
            plans.append(plan); tasks.append(contentsOf: work)
            garden.carePlans = plans; garden.careTasks = tasks
            if let index = garden.records.firstIndex(where: { $0.id == observationID }) {
                if let pest { garden.records[index].assessment = pest }
                if let leaf { garden.records[index].leafAssessment = leaf }
            }
        }) else { return nil }
        return plan.id
    }

    func finishPlanAction(taskID: UUID, skipped: Bool = false, note: String = "", now: Date = .now, wateringAction: CareAction? = nil) -> PlanTaskReceipt? {
        guard let task = careTask(taskID), task.status == .pending, task.step != .review,
              let plan = carePlan(task.planID), planIsOpen(plan.id) else { return nil }
        if task.step == .waterDryRoots && !skipped && wateringAction != .watered && wateringAction != .waited { return nil }
        let actualWatering = task.step == .waterDryRoots && !skipped ? wateringAction : nil
        let record = CareRecord(plantID: task.plantID, date: now, kind: .careAction, action: actualWatering, note: note, parentID: plan.observationID,
                                outcome: skipped ? "Skipped" : "Done", planID: plan.id, planTaskID: task.id, actionTitle: task.step.title)
        guard commit({ garden in
            guard let index = garden.careTasks?.firstIndex(where: { $0.id == task.id }) else { return }
            garden.careTasks?[index].status = skipped ? .skipped : .completed
            garden.careTasks?[index].completedAt = skipped ? nil : now
            garden.records.insert(record, at: 0)
            garden.updateAutomaticReview(for: plan.id)
        }) else { return nil }
        return PlanTaskReceipt(task: task, previousStatus: plan.status, recordID: record.id)
    }

    func finishPlanReview(taskID: UUID, outcome: PlanOutcome, note: String, photo: Data? = nil, now: Date = .now) -> PlanTaskReceipt? {
        guard let task = careTask(taskID), task.step == .review, task.status == .pending,
              let plan = carePlan(task.planID), planIsOpen(plan.id) else { return nil }
        let record = CareRecord(plantID: task.plantID, date: now, kind: .followUp, observation: plan.baseline.observation, note: note, photo: photo,
                                parentID: plan.observationID, outcome: outcome.title(for: plan.kind), planID: plan.id, planTaskID: task.id)
        guard commit({ garden in
            guard let index = garden.careTasks?.firstIndex(where: { $0.id == task.id }),
                  let p = garden.carePlans?.firstIndex(where: { $0.id == plan.id }) else { return }
            garden.careTasks?[index].status = .completed; garden.careTasks?[index].completedAt = now
            garden.carePlans?[p].status = outcome == .worse || outcome == .unclear ? .needsReview : .active
            garden.records.insert(record, at: 0)
        }) else { return nil }
        return PlanTaskReceipt(task: task, previousStatus: plan.status, recordID: record.id)
    }

    func canUndoPlanTask(_ receipt: PlanTaskReceipt) -> Bool {
        guard let current = careTask(receipt.task.id), current.status == .completed || current.status == .skipped,
              let record = record(receipt.recordID), planIsOpen(current.planID) else { return false }
        guard let index = garden.records.firstIndex(where: { $0.id == record.id }) else { return false }
        // Dependency order uses when records were saved, not a backdated action time.
        return !garden.records.prefix(index).contains { $0.planID == current.planID && $0.kind == .followUp }
    }
    func undoPlanTask(_ receipt: PlanTaskReceipt) -> Bool {
        guard canUndoPlanTask(receipt) else { return false }
        return commit { garden in
            guard let i = garden.careTasks?.firstIndex(where: { $0.id == receipt.task.id }),
                  let p = garden.carePlans?.firstIndex(where: { $0.id == receipt.task.planID }) else { return }
            // Preserve a date/notification preference changed after completing this task.
            let current = garden.careTasks![i]
            garden.careTasks?[i] = receipt.task
            if current.customDate { garden.careTasks?[i].due = current.due; garden.careTasks?[i].customDate = true }
            garden.careTasks?[i].notifications = current.notifications
            garden.carePlans?[p].status = receipt.previousStatus
            garden.records.removeAll { $0.id == receipt.recordID }
            if receipt.task.step != .review { garden.updateAutomaticReview(for: receipt.task.planID) }
        }
    }

    func reschedulePlanTask(_ id: UUID, date: Date, now: Date = .now) -> Bool {
        guard let task = careTask(id), task.status == .pending, planIsOpen(task.planID), date > now else { return false }
        return commit { garden in
            if let index = garden.careTasks?.firstIndex(where: { $0.id == id }) { garden.careTasks?[index].due = date; garden.careTasks?[index].customDate = true }
        }
    }
    func reviewPlanNow(_ id: UUID, now: Date = .now) -> UUID? {
        guard let plan = carePlan(id), planIsOpen(id), tasks(for: id).contains(where: { $0.step != .review && $0.status == .completed }) else { return nil }
        if let existing = tasks(for: id).first(where: { $0.step == .review && $0.status == .pending && ($0.due ?? .distantFuture) <= now }) { return existing.id }
        let next = PlanTask(plantID: plan.plantID, planID: id, step: .review, position: tasks(for: id).count, due: now, customDate: true)
        guard commit({ garden in
            // An extra early check-in doesn't consume the check after all actions.
            garden.careTasks = (garden.careTasks ?? []) + [next]
        }) else { return nil }
        return next.id
    }
    func schedulePlanReview(_ id: UUID, date: Date, now: Date = .now) -> Bool {
        guard date > now, let plan = carePlan(id), planIsOpen(id), tasks(for: id).contains(where: { $0.step != .review && $0.status == .completed }) else { return false }
        if let pending = tasks(for: id).first(where: { $0.step == .review && $0.status == .pending }) { return reschedulePlanTask(pending.id, date: date, now: now) }
        let next = PlanTask(plantID: plan.plantID, planID: id, step: .review, position: tasks(for: id).count, due: date, customDate: true)
        return commit { garden in
            garden.careTasks = (garden.careTasks ?? []) + [next]
        }
    }
    func closePlan(_ id: UUID, resolved: Bool) -> Bool {
        guard planIsOpen(id) else { return false }
        if resolved {
            guard PlanOutcome.fromStored(garden.records.filter({ $0.planID == id && $0.kind == .followUp }).max(by: { $0.date < $1.date })?.outcome) == PlanOutcome.none else { return false }
        }
        return commit { garden in
            if let index = garden.carePlans?.firstIndex(where: { $0.id == id }) { garden.carePlans?[index].status = resolved ? .resolved : .stopped }
            for i in (garden.careTasks ?? []).indices where garden.careTasks?[i].planID == id && garden.careTasks?[i].isOpen == true { garden.careTasks?[i].status = .cancelled }
        }
    }

    func enablePlanNotification(_ id: UUID) async -> String? {
        guard allowsPlanNotifications, let task = careTask(id), task.status == .pending, let due = task.due, due > Date() else { return "Choose a future task date first. Your task is saved in Bloom." }
        guard appPreferences.taskNotifications else { return "Task notifications are off. Enable them in Preferences; your task stays in Bloom." }
        guard await notificationClient.access() == .allowed else { return "Notifications are off in iOS Settings. Your task remains in Bloom." }
        guard commit({ garden in
            if let index = garden.careTasks?.firstIndex(where: { $0.id == id }) { garden.careTasks?[index].notifications = true }
        }) else { return "Your notification preference couldn't be saved." }
        await waitForNotificationSync()
        return notificationMessage
    }

    func disablePlanNotification(_ id: UUID) -> Bool {
        commit { garden in
            if let index = garden.careTasks?.firstIndex(where: { $0.id == id }) { garden.careTasks?[index].notifications = false }
        }
    }
    func syncPlanTaskNotifications() async {
        guard allowsPlanNotifications else { return }
        notificationMessage = nil
        let pending = await notificationClient.pending()
        let access = await notificationClient.access()
        let canNotify = appPreferences.taskNotifications && access == .allowed
        var desired: [UNNotificationRequest] = []
        if canNotify {
            for plant in garden.plants {
                guard let due = plant.reminder, due > Date() else { continue }
                let soil = (plant.reminderKind ?? .soilCheck) == .soilCheck
                let content = UNMutableNotificationContent()
                content.title = "\(soil ? "Check soil" : "Look again") · \(plant.name)"
                content.body = soil ? "Check the soil before deciding whether to water." : "Compare your plant with your last observation."
                content.userInfo = ["plantID": plant.id.uuidString]; content.sound = .default
                let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: due), repeats: false)
                desired.append(UNNotificationRequest(identifier: plant.id.uuidString, content: content, trigger: trigger))
            }
            for task in openPlanTasks where task.notifications {
                guard let due = task.due, due > Date() else { continue }
                let content = UNMutableNotificationContent()
                content.title = "\(task.step.title) · \(plant(task.plantID)?.name ?? "Your plant")"
                content.body = task.step == .review ? "Compare your original observation with the actions you've recorded." : "Open your care plan for instructions before recording the action."
                content.userInfo = ["taskID": task.id.uuidString, "plantID": task.plantID.uuidString]; content.sound = .default
                let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: due), repeats: false)
                desired.append(UNNotificationRequest(identifier: "bloom-plan-\(task.id.uuidString)", content: content, trigger: trigger))
            }
        }
        let identifiers = Set(desired.map(\.identifier))
        let owned = pending.filter { $0.identifier.hasPrefix("bloom-plan-") || $0.content.userInfo["plantID"] != nil || UUID(uuidString: $0.identifier) != nil }
        notificationClient.remove(owned.filter { !identifiers.contains($0.identifier) }.map(\.identifier))
        for request in desired {
            do { try await notificationClient.add(request) }
            catch { notificationMessage = "Your tasks are saved. Some alerts couldn't be scheduled. Try enabling task notifications again." }
        }
    }

}

extension Garden {
    /// Recompute only the automatic, not user-picked, review date from real action completions.
    mutating func updateAutomaticReview(for planID: UUID) {
        guard let planIndex = carePlans?.firstIndex(where: { $0.id == planID }), let plan = carePlans?[planIndex] else { return }
        let actions = (careTasks ?? []).filter { $0.planID == planID && $0.step != .review }
        let terminal = !actions.isEmpty && actions.allSatisfy { $0.status == .completed || $0.status == .skipped }
        let lastCompletion = actions.compactMap(\.completedAt).max()
        if terminal && lastCompletion == nil { carePlans?[planIndex].status = .needsReview }
        guard let days = plan.reviewAfterDays else { return }
        for index in (careTasks ?? []).indices where careTasks?[index].planID == planID && careTasks?[index].step == .review && careTasks?[index].isOpen == true {
            guard careTasks?[index].customDate != true else { continue }
            careTasks?[index].status = terminal && lastCompletion != nil ? .pending : .waiting
            careTasks?[index].due = terminal ? lastCompletion.flatMap { Calendar.current.date(byAdding: .day, value: days, to: $0) } : nil
        }
    }
    mutating func removeCareRecords(startingAt root: UUID) {
        var ids: Set<UUID> = [root]
        while true {
            let expanded = ids.union(records.filter { $0.parentID.map(ids.contains) == true }.map(\.id))
            if expanded == ids { break }; ids = expanded
        }
        let plans = Set((carePlans ?? []).filter { ids.contains($0.observationID) }.map(\.id))
        for i in self.plants.indices where self.plants[i].reminderObservationID.map(ids.contains) == true {
            self.plants[i].reminder = nil; self.plants[i].reminderKind = nil; self.plants[i].reminderObservationID = nil
        }
        records.removeAll { ids.contains($0.id) || $0.planID.map(plans.contains) == true }
        carePlans?.removeAll { plans.contains($0.id) }; careTasks?.removeAll { plans.contains($0.planID) }
    }
}


extension BloomStore {
    func announceCarePlan(_ id: UUID) {
        guard let plan = carePlan(id) else { return }
        careFeedback = CareFlowFeedback(plantID: plan.plantID, title: "Care plan added", detail: "Next: \(plan.kind.actionSteps.first?.title ?? "Check your plant").", planID: id)
    }

    func announceCareTask(_ receipt: PlanTaskReceipt) {
        guard let record = record(receipt.recordID), let plan = carePlan(receipt.task.planID) else { return }
        let title: String
        let detail: String
        if record.kind == .followUp {
            title = "Check-in saved"
            switch PlanOutcome.fromStored(record.outcome) {
            case .worse, .unclear: detail = "Let's review the next step before trying another treatment."
            case .some(.none): detail = "No concerning changes? You can mark this issue as resolved."
            default: detail = "Keep watching for new changes. Your comparison is saved in Activity."
            }
        } else {
            title = record.outcome == "Skipped" ? "Action skipped" : "Action recorded"
            if let action = tasks(for: plan.id).first(where: { $0.step != .review && $0.status == .pending }) {
                detail = "Next: \(action.step.title)."
            } else if let review = tasks(for: plan.id).first(where: { $0.step == .review && $0.status == .pending }), let due = review.due {
                detail = "Check again \(due.formatted(date: .abbreviated, time: .omitted))."
            } else if plan.status == .needsReview { detail = "Review your next step. No check-in timer has started." }
            else { detail = "Saved in Activity. You can check progress from your care plan." }
        }
        careFeedback = CareFlowFeedback(plantID: plan.plantID, title: title, detail: detail, planID: plan.id, receipt: receipt)
    }
}
