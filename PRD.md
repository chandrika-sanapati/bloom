# Bloom — Product Requirements Document

**Status:** Draft v0.5 — smallest credible watering MVP and case-study plan
**Owner:** Bloom product team
**Last updated:** 14 November 2026
**Product:** Bloom, a native iOS plant-care companion

## 1. Product summary

Bloom helps plant owners care for their existing plants with less cognitive effort and more confidence. It turns a plant collection into a small set of timely, understandable care actions, records what actually happened, and uses that history to make the next action more useful.

The first product obligation is reliable watering support. Every plant in a user's collection should have a watering schedule appropriate to its plant type. Bloom should tell the user what needs attention, let them record the watering, and keep the next reminder aligned with what actually happened. A missed reminder should become overdue rather than silently disappearing or being treated as completed.

Bloom is an assistant, not an automatic diagnosis engine. A schedule is a starting point and a reminder to inspect the plant, not a claim that a plant always needs water on a fixed date. The experience should make the safe next action obvious while keeping the user in control.

## 2. Problem statement

Plant owners commonly need to remember several different care intervals across plants with different needs. The work is easy to postpone, and once a task is missed it becomes difficult to know whether to:

- water immediately;
- move the next date forward;
- keep the original cadence;
- or record that the plant was checked but intentionally not watered.

Existing plant-care tools often create one of two problems:

1. **Too little help:** a static list of plants does not reduce memory burden.
2. **False precision:** a rigid calendar treats every plant and every home as identical and can encourage watering by date instead of by plant condition.

Bloom should reduce remembering and recording work without hiding the uncertainty inherent in plant care.

## 3. Current product baseline

The current app already provides a strong foundation:

- A local plant collection with common and scientific names, optional photos, placement, light, drainage, and plant history.
- Plant detail pages with a Recent care summary, including **Last soil check** and **Last watered**.
- A one-off reminder model attached to a plant, shown in **Activity → Upcoming** and grouped as Overdue, Today, or Upcoming.
- A soil-check flow where the user records soil state and chooses a watering outcome; the watering MVP simplifies this to **Watered** or **Checked — not watered**.
- Care records and an activity history with Undo for supported completions.
- Local notification preferences, a default reminder time, and native iOS notification scheduling.
- Separate care-plan tasks for observations and issue follow-ups.

The important gap is that the current ordinary reminder is a generic, one-off soil-check reminder. It does not yet provide a recurring watering schedule derived from plant type, nor does it consistently model a watering occurrence, missed watering, and the next watering interval as one product concept. Existing care-plan tasks and issue reminders must continue to coexist with watering tasks rather than being replaced by them.

## 4. Product vision

When a user opens Bloom, they should quickly understand:

1. **What needs attention now?**
2. **Which plant is it for?**
3. **What should I do or check?**
4. **What did I last do, and when will Bloom remind me again?**

The ideal recurring loop is:

> Bloom suggests a watering check → the user checks the plant → the user records watered or not watered → Bloom schedules the next appropriate check → the history remains trustworthy.

## 5. Goals and non-goals

### Goals

- Give each supported catalog plant a watering schedule after it is added.
- Base the initial suggested interval on the plant type, with clear language that the interval is a starting point.
- Surface due and overdue watering work in the existing Activity experience.
- Make recording a watering or a deliberate non-watering decision fast and unambiguous.
- Adjust the next schedule using the actual recorded outcome, especially when a task is completed late.
- Preserve a trustworthy history of scheduled tasks, watering events, and completed non-watering checks.
- Keep plant-type schedules, user adjustments, and notification preferences separate from issue-specific care plans.
- Support accessibility, Dynamic Type, VoiceOver, local-only storage, and native iOS interaction patterns.

### Non-goals for this milestone

- Automatic watering through hardware or smart-home integrations.
- Photo-based disease or moisture diagnosis.
- Live weather, climate, or location-based schedule calculation.
- A guarantee that a plant needs water solely because a date has arrived.
- Automatic watering schedules for custom or unlisted plants in the MVP.
- Replacing the existing observation and care-plan journeys.
- Accounts, cloud sync, social features, or a community watering calendar.
- A large plant-care encyclopedia or a generic treatment recommendation engine.

## 6. Target users and primary use case

### Primary user

A person with several indoor plants who wants healthy plants but does not want to remember a separate care routine for each one.

### Primary job to be done

> When one of my plants may need water, help me know which plant to check, remind me at a sensible time, and let me record what I actually did so I do not have to remember it later.

### Primary scenario

The user has added a Snake Plant, Monstera, and Pothos. Each supported plant receives a type-based baseline watering interval. Bloom shows the next task in Activity. On the due date, the user checks the plant and records either **Watered** or **Checked — not watered**. If they do not act, the task remains visible as **Overdue**. When they eventually record an outcome, Bloom calculates the next check from the actual event and the plant profile's interval.

## 7. Product principles

### Reduce memory, not agency

Bloom should remember dates and history for the user, but it should not pretend to know the plant's condition without a check.

### Scheduled does not mean watered

A due or overdue task means “check this plant,” not “pour water without looking.” The task language must make that distinction clear.

### Record reality, including “not watered”

Checking a plant and choosing not to water is a meaningful care event. Bloom must not log watering unless the user explicitly confirms that water was given.

### Late completion changes the future, not the past

When a user completes a task late, the original due date remains part of the history. The next schedule is anchored to the actual recorded event so the user is not immediately presented with another stale task.

### One primary action

The home experience should prioritize the next care action. Settings, interval editing, history, and advanced controls should remain secondary.

## 8. Watering schedule model

### 8.1 Schedule terminology

- **Watering profile:** the plant-type guidance used to suggest an interval.
- **Suggested interval:** the default number of days between watering checks for a plant type.
- **Profile interval:** the deterministic interval used by a supported plant profile for the MVP.
- **Next check:** the date/time when Bloom asks the user to inspect and decide whether to water.
- **Due:** the next check is today or in the current due window.
- **Overdue:** the next check is in the past and has not been resolved.
- **Watering event:** an explicit record that the user watered the plant.
- **Care check:** an explicit record that the user checked the plant and did or did not water it.

### 8.2 Initial schedule creation

When a plant is added:

1. Bloom identifies its plant type when the type is known in the catalog.
2. Bloom applies that type's suggested interval.
3. Bloom asks for an optional last-watered date during plant setup or from the plant's first schedule screen.
4. If the user provides a valid last-watered date, Bloom calculates the first next-check date from that date plus the deterministic starting interval.
5. If the user does not know the last-watered date, Bloom creates a first check for today using the product's default reminder time. This establishes a baseline without making the user wait through an unknown interval.
6. Bloom explains that the schedule is a starting point and can be adjusted after observing the plant.
7. Automatic watering schedules are available only for the four supported catalog plants in the MVP. Custom or unlisted plants can still be saved, but show **Set up watering schedule** rather than receiving an invented interval.

The first-check hybrid rule must handle dates safely:

- A future last-watered date is invalid and cannot be saved as the basis for scheduling.
- A past last-watered date may produce an immediately due or overdue check; Bloom should show that state clearly rather than hiding it.
- If the user is unsure whether the plant was watered recently, **I don't know** should be easier to choose than inventing a date, and should route to today's baseline check.

The first schedule should not require a long setup questionnaire. Optional detail collection must not block adding the plant or getting to the first care action.

#### Decision rationale: first-task timing

Options considered:

1. **Due immediately** — establish a baseline with every newly added plant.
2. **Based on the user's last-watered date** — calculate the first check from known care history.
3. **Due after the full starting interval** — wait the entire plant-type interval after setup.

The MVP chooses a **hybrid of options 1 and 2**. Use the last-watered date when the user knows it; otherwise create a check for today. This preserves useful history when it exists and gives every new plant a meaningful first interaction without forcing the user to wait or complete a long setup flow. The full-interval option was rejected as the sole behavior because it leaves Bloom without a baseline and can delay help for a plant whose condition is already unknown.

### 8.3 Recommended schedule calculation

For a first implementation, the next check should use this rule:

```text
next check = actual recorded care-check date + supported plant profile interval
```

If there is no recorded care-check date, use the date the schedule was created or the user's supplied “last watered” date, if available.

When a due task is completed late, Bloom should **not** create a second immediate task based on the old due date. The original task is resolved, and the next task starts from the recorded completion date.

For a **Checked — not watered** result, Bloom should schedule another check using the supported plant profile interval from the check date. It should not update `Last watered`. A dry or concerning condition may replace that normal interval with the shorter 3-day follow-up defined below.

The MVP refines that rule using the observed condition:

- If the soil is **dry** or the plant is marked as needing attention, Bloom schedules a shorter follow-up check. The deterministic starting follow-up is **3 days**, with a bounded editable window of **2–5 days**.
- If the soil is **damp** and the plant appears healthy, Bloom uses the normal plant interval.
- If the soil or condition is **unknown**, Bloom does not pretend to know that the plant needs water; it uses the normal interval unless the user explicitly chooses a shorter follow-up.
- The shorter follow-up is a check-in, not an instruction to water. The user must inspect the plant again before deciding.
- The outcome still creates a care-check record, does not update `Last watered`, and does not create a watering event.

#### Decision rationale: follow-up after not watering

Options considered:

1. **Use the normal plant interval** for every Checked — not watered result.
2. **Always use a shorter follow-up** because the plant was not watered.
3. **Condition-based follow-up** — use a shorter follow-up only when the soil is dry or the plant needs attention; otherwise use the normal interval.

The MVP chooses **option 3**. A universal interval is too slow when a dry or concerning plant needs another look, while an always-short interval creates unnecessary reminders for a healthy plant that was correctly left unwatered. The condition-based rule keeps the next action proportional to the evidence without treating “not watered” as a failure.

For a **Watered** result, Bloom should update `Last watered` and schedule the next check from the watering event date. The record should retain both the scheduled date and actual completion date where those differ.

This policy is deliberately simple for the MVP. A later adaptive model may use plant condition, seasonality, environment, and repeated user outcomes, but it must remain explainable and must not silently change an individual's schedule.

### 8.4 Overdue behavior

- A missed task remains visible as **Overdue** until the user records an outcome or explicitly changes the schedule.
- The task does not automatically move forward every day.
- An overdue task does not imply that the plant must be watered.
- The user can open an overdue task, inspect the plant, and choose **Watered** or **Checked — not watered**.
- If the user does nothing, the task remains overdue; Bloom does not create a deferred activity or silently move the task.
- Notifications must not create a burst of historical alerts for overdue tasks. At most, Bloom may notify for the next future schedule after the user resolves the overdue task.

### 8.5 User overrides

The MVP should support changing the next check date from a plant's watering schedule details. The UI should show:

- plant-type suggested interval;
- the next check date;
- a concise explanation that real conditions may require checking before watering.

Changing the next check date requires an explicit save and confirmation. It changes future timing only; it must not rewrite previous care history or alter the original plant-type guidance. Per-plant interval editing is post-MVP.

### 8.6 Temporary schedule changes — explicit editing only

The MVP does not provide a per-plant pause/resume state or calendar-triggered seasonal suggestions. A plant's watering schedule remains active after it is created. If the user's situation changes temporarily—travel, dormancy, relocation, or a change in care responsibility—the user can explicitly edit the next-check date from schedule details.

- An untouched task remains visible as **Overdue**; it is not automatically dismissed, deferred, or paused.
- Editing the next-check date requires an explicit save and confirmation of the resulting future date.
- Schedule editing changes future timing only; it does not create a care record or imply that watering occurred.
- Notifications follow the newly saved future date and the existing global notification preference.
- The original plant-type suggestion and completed history remain unchanged.
- The MVP does not calculate seasonal changes from the calendar, device location, or live weather.
- A later release may add pause/resume or seasonal guidance after the core watering loop is validated.

### 8.7 Optional growing-context modifiers — post-MVP

Pot size, light exposure, room/location, drainage, growing medium, and indoor/outdoor placement may eventually improve watering suggestions, but they are intentionally **out of scope for the watering MVP**. The optional three-choice plant-location context is also deferred to the later environmental-check release.

- The MVP schedule is based on the supported plant type's bounded profile and deterministic starting value. The user may explicitly edit the next check date, but not the interval.
- Existing plant details remain available for display and future use, but they must not silently modify the watering interval in the MVP.
- These fields should not become required setup questions merely to create a watering schedule.
- A later version may use them to produce a transparent suggestion, such as: **“Your Pothos is in bright light and a small pot. Consider checking it a little sooner.”**
- Any future modifier must explain which context influenced the suggestion, provide a clear accept/dismiss choice, and preserve the user's current schedule unless explicitly changed.
- The first modifier experiment should be limited to one or two high-value signals and validated before combining multiple factors.

#### Decision rationale: growing-context modifiers

Options considered:

1. **Use context in the MVP** — adjust schedules from pot size, light, room, drainage, medium, or placement.
2. **Collect context but apply it automatically** — retain the fields while silently recalculating schedules.
3. **Keep modifiers out of the MVP** — use plant type and explicit user adjustments first; consider transparent suggestions later.

The MVP chooses **option 3**. These factors matter, but using several of them immediately would increase setup complexity, make schedule changes harder to explain, and make testing less deterministic. Keeping them out of schedule calculation protects the simple first-run experience. Existing details remain available so a future experiment can be introduced deliberately and evaluated with users.

### 8.8 Correcting a past watering record

The MVP will use **deletion** as the correction flow for a mistakenly recorded watering event. This is a deliberate UX decision: adding a correction record would preserve more audit detail but would introduce a second layer of records that users would need to understand; editing in place would be less transparent; deletion is the simplest mental model for correcting an accidental entry.

#### Options considered

1. **Edit the past record** — change Watered to Checked — not watered, or change the date/note in place, then recalculate the schedule.
2. **Add a correction record** — preserve the original event and add a visible correction explaining what changed.
3. **Delete the mistaken record** — remove the incorrect entry and restore or recalculate the affected schedule.

#### Decision

Choose **option 3: delete the mistaken record** for the MVP.

The deletion flow must remain explicit and predictable:

- A user can choose **Delete record** from the most recent watering record's detail view.
- Bloom shows a native confirmation explaining what will be removed and whether the next watering check will change.
- Deletion is limited to the most recent watering record in the MVP; older watering records remain unchanged.
- Deletion removes the selected mistaken watering record; it must not silently delete unrelated care records, observation history, care-plan tasks, or later schedule changes.
- Bloom recalculates `Last watered` and the next check from the remaining valid state. If no prior valid state exists, the schedule returns to its baseline/setup state.
- `Last watered` is recalculated from the remaining explicit watering history. A deleted event must never continue to appear as the last watering date.
- The most-recent-only restriction prevents deletion from rewriting later watering events or reconstructing an ambiguous chain of historical schedule decisions.
- Deleting a record is not the same as recording **Checked — not watered**. The former removes an accidental entry; the latter records a real care decision.
- The MVP may provide a short immediate Undo after deletion, but it must not require users to understand correction records.
- Deletion should be available only for the user's own saved records, not for immutable source/profile guidance.

This decision should be revisited if later versions add multi-device sync, shared plant ownership, compliance/audit requirements, or analytics that depend on immutable event history. For the local-only MVP, clarity and low interaction cost take priority over a full correction ledger.

### 8.9 Watering activity history and progressive disclosure

The MVP will include all meaningful watering outcomes in the existing **Activity → Past** feed, without creating a separate watering-history area:

- **Watered** — the user explicitly gave the plant water.
- **Checked — not watered** — the user inspected the plant and intentionally did not water it.
The default experience must remain compact and task-focused:

- Home/Past continues to show the five most recent saved activities.
- Each watering record uses concise, verb-led language, such as **“Watered · Pothos”** or **“Checked, not watered · Snake Plant.”**
- A watering/soil tag distinguishes these records from observations, care-plan actions, and future environmental checks.
- Schedule configuration events—interval changes and future post-MVP pause/seasonal controls—stay in watering schedule details rather than cluttering the main care history.
- **See all** continues to use the existing history experience. New watering-specific filters and search are post-MVP and are not required for the watering release.
- Deleted records disappear from the visible activity history.

#### Decision rationale: watering history

Options considered:

1. **Show both meaningful completed watering outcomes in the existing Past feed.**
2. **Show only actual watering events.**
3. **Create a separate watering history.**

The MVP chooses **option 1 with progressive disclosure**. Showing only Watered would lose the meaningful distinction between a plant that was checked and intentionally left dry and a plant that was never checked. A separate history would create another navigation destination and force users to decide where watering records belong. Putting the two completed outcomes in Past keeps care history unified, while compact rows and a five-item default prevent unnecessary complexity. An untouched overdue task is not added to Past.

This decision should be revisited if the activity feed becomes too dense after additional care domains are added. The preferred response would be better grouping and filtering before creating another parallel history system.

## 9. Functional requirements

### FR-1: Every plant has a visible watering state

For each plant, Bloom must show one of:

- **Due today**;
- **Overdue**;
- **Next check [date]**;
- **Schedule active** after creation; temporary changes use explicit schedule editing.

Custom or unlisted plants must remain visible with an explicit **Set up watering schedule** state; they must not receive an invented automatic interval or silently disappear.

### FR-2: Activity prioritizes watering work

In **Activity → Upcoming**, watering checks should appear as task-first rows alongside existing care-plan and observation tasks. Each row should contain:

- action label, such as **Check watering**;
- plant name;
- due state/date;
- a semantic watering/soil tag;
- a clear navigation affordance.

Overdue and Today groupings remain useful. The feed must distinguish a recurring watering check from an observation reminder or care-plan action.

### FR-3: Watering task flow

Opening a watering task should take the user directly to a compact, plant-specific check screen. The screen must include:

- plant identity and current schedule context;
- last watered date, if recorded;
- optional soil condition selection;
- one required outcome: **Watered** or **Checked — not watered**;
- a single primary save action;
- a secondary route to edit the schedule.

The default action must never be preselected in a way that could record watering accidentally.

### FR-4: Record actual watering

When the user chooses **Watered** and saves:

- Bloom creates a care record with the actual event date/time.
- `Last watered` updates to that event.
- The current watering task resolves.
- The next check is scheduled from the actual event date plus the supported plant profile interval.
- The result appears in Past activity.
- The user receives immediate confirmation and an Undo option where safe.

### FR-5: Record a non-watering check

When the user chooses **Checked — not watered** and saves:

- Bloom creates a care-check record.
- `Last watered` remains unchanged.
- The current task resolves as a check, not a watering event.
- The next check is scheduled from the actual check date plus the supported plant profile interval, unless the user has explicitly edited the next-check date.
- The result appears in Past activity with wording that makes no watering clear.

### FR-6: Schedule details and editing

The plant detail page should expose a concise watering schedule section containing:

- current schedule status;
- next check;
- suggested plant-type range and starting value;
- last watered;
- an explicit **Edit next check** action.

Schedule editing must not be mixed into the task completion control or hidden behind an icon-only action.

### FR-7: Notifications

Watering notifications must use the existing global task-notification preference and default reminder time. They must:

- be scheduled only for future tasks;
- link to the matching plant and watering task;
- respect the user's global preference;
- remain saved in-app if notification permission is denied;
- avoid overdue notification bursts;
- be removed or updated when a task is completed or its date changes.

### FR-8: Persistence and integrity

Watering schedules and records must survive app relaunch. Saving a watering outcome and its next schedule must be atomic: either both are saved or neither is saved. Undo must restore the prior task state and watering history without deleting later user changes.

Existing plant records, issue care plans, ordinary reminders, and notification preferences must remain compatible with existing local garden files.

### FR-9: Accessibility and native behavior

- All controls have at least a 44-point target.
- VoiceOver distinguishes **Watered** and **Checked — not watered**.
- Selected state is communicated by label and native accessibility state, not color alone.
- Dynamic Type reflows task rows, schedule metadata, and action choices without truncation.
- Native navigation, date pickers, alerts, and permission controls are retained.
- Reduce Motion is respected.

## 10. Data model direction

The current `Plant.reminder`, `Plant.reminderKind`, and `Plant.lastWatered` fields are useful compatibility foundations, but a recurring watering schedule should become a first-class concept rather than overloading a one-off reminder.

The target model should conceptually include:

```text
WateringSchedule
- plantID
- suggestedIntervalDays
- profileIntervalDays
- source: plantType
- nextCheckAt
- status: active
- defaultReminderTime
- updatedAt

WateringEvent / CareCheck
- id
- plantID
- scheduledFor
- recordedAt
- outcome: watered | checkedNotWatered
- soilCondition (optional)
- note (optional)
- previousNextCheckAt (for audit/Undo)
```

The exact Swift type names are an implementation decision. The migration must preserve existing gardens and must not interpret an old observation reminder as a watering event. Existing care-plan tasks remain separate entities.

## 11. Initial plant-type watering profiles

### Decision: bounded range with deterministic starting value

The watering MVP will use a bounded range with a deterministic starting value for the four existing catalog plants only. Bloom will schedule the starting value automatically, while showing the broader range as context. This avoids false precision without asking the user to choose a horticultural interval during plant setup.

These are **check-in intervals**, not instructions to water on a date. At each check, the user should inspect the soil and plant before deciding whether to water. Actual needs vary with pot size, drainage, growing medium, light, temperature, humidity, season, and plant size.

| Catalog plant | Scientific name | Bloom check-in range | Initial value | Care cue |
| --- | --- | ---: | ---: | --- |
| Snake Plant | *Dracaena trifasciata* | 14–30 days | 21 days | Let the growing medium dry substantially; overwatering is a significant risk. |
| Monstera | *Monstera deliciosa* | 7–14 days | 10 days | Check the top 1–2 inches of soil; water only when the plant needs it and avoid waterlogging. |
| Rubber Plant | *Ficus elastica* | 7–21 days | 14 days | Water moderately during active growth and more sparingly in lower-growth periods; use a free-draining medium. |
| Pothos | *Epipremnum aureum* | 7–21 days | 14 days | Allow the soil to dry between checks; the top layer should not remain constantly wet. |

The ranges are product starting points synthesized from the cited care guidance, not claims that the sources prescribe those exact universal intervals. Bloom should present them as **“Check about every X–Y days; starting suggestion: Z days”** and should always pair the date with a soil/plant inspection cue.

#### Source notes

- [RHS — Sansevieria / Snake Plant](https://www.rhs.org.uk/plants/16407/sansevieria/details): allow compost to dry between waterings, avoid overwatering, and water sparingly in winter.
- [Penn State Extension — Snake Plant](https://extension.psu.edu/snake-plant-a-forgiving-low-maintenance-houseplant/): snake plants tolerate being left without water for about a month, supporting a less-frequent, conservative check-in profile.
- [RHS — Monstera deliciosa](https://www.rhs.org.uk/plants/11192/i-monstera-deliciosa-i-(f)/details): water during growth and keep the medium just moist in winter.
- [University of Minnesota Extension — Monstera deliciosa](https://extension.umn.edu/garden-and-home/yard-and-garden/gardening-in-minnesota/propagating-monstera-deliciosa): mature plants are commonly watered weekly, or when the top 1–2 inches of soil are dry.
- [RHS — Ficus elastica / Rubber Plant](https://rhs.org.uk/plants/95720/ficus-elastica/details): rubber plants are grown in well-drained conditions and need moderate watering during growth and less in winter; related RHS cultivar guidance recommends monthly feeding during growth and sparing winter watering.
- [Clemson Extension — Rubber Plant](https://hgic.clemson.edu/factsheet/rubber-plant/): additional university extension care guidance for *Ficus elastica* and indoor growing conditions.
- [RHS — Epipremnum / Pothos](https://rhs.org.uk/plants/epipremnum): avoid excessive watering and let the top 2 cm of compost dry between waterings.
- [Penn State Extension — Pothos](https://extension.psu.edu/pothos-as-a-houseplant): water when dry and fertilize occasionally.

The profiles should be versioned as product content. Changing a suggested range must not silently rewrite a user's saved schedule, completed history, or already-recorded next check. A later content review can adjust the ranges and sources independently from the scheduling engine.

#### Decision rationale: watering-profile format

Options considered:

1. **One fixed interval per plant type** — simple but implies false precision.
2. **A bounded range with a deterministic starting value** — communicate natural variation while keeping setup automatic.
3. **Ask the user to choose within a range during setup** — maximize personalization immediately.

The MVP chooses **option 2** for the four existing catalog plants. A fixed interval was rejected because household conditions vary; asking users to choose was rejected because it transfers a horticultural decision to setup and adds friction. A deterministic starting value keeps behavior predictable for the product and testable for engineering, while the range and explicit adjustments preserve user control.

## 12. Key user journeys

### Journey A: Add a known plant

1. User searches and selects a known plant type.
2. User adds the plant with optional details or skips them.
3. Bloom creates the plant and its watering schedule.
4. Plant detail confirms the next watering check.
5. The task appears in Activity → Upcoming.

### Journey B: Complete an on-time watering check

1. User opens the watering task.
2. User checks the soil/plant.
3. User selects **Watered**.
4. User saves.
5. Bloom confirms the watering, updates Last watered, and shows the next check.

### Journey C: Complete an overdue task without watering

1. User sees the plant under Overdue.
2. User opens the task and checks the plant.
3. User selects **Checked — not watered**.
4. Bloom records the check without changing Last watered.
5. Bloom schedules the next check from the actual check date.

### Journey D: Miss and later resolve a task

1. The due date passes without user action.
2. The task remains under Overdue.
3. The user later opens it and chooses **Watered**.
4. History retains the original scheduled date and late recorded date.
5. The next check is based on the late recorded date, not the stale due date.

### Journey E: Add an unsupported custom plant

1. User adds an unlisted plant by name.
2. Bloom explains that automatic watering schedules are currently available only for the four supported catalog plants.
3. Bloom saves the plant without inventing a watering interval.
4. Plant details show **Set up watering schedule** as an explicit future setup state.

## 13. Acceptance criteria for watering MVP

The watering milestone is complete when:

- [ ] Each newly added supported catalog plant receives a persistent, type-based watering schedule.
- [ ] Every existing plant receives a migration-safe watering state without losing current history or issue tasks.
- [ ] The next watering check is visible on the plant page and in Activity.
- [ ] Due, Today, Upcoming, and Overdue states are derived from the current date and rendered consistently.
- [ ] A watering task can be completed with an explicit Watered outcome.
- [ ] A check can be completed with an explicit Checked — not watered outcome.
- [ ] Watered updates Last watered; non-watering outcomes do not.
- [ ] A dry or concerning Checked — not watered result offers a 3-day follow-up adjustable between 2–5 days; a damp, healthy result uses the normal interval.
- [ ] A late completion resolves the old task and schedules the next check from the actual recorded event.
- [ ] Overdue tasks remain visible until acted upon and never generate a notification burst.
- [ ] Users can explicitly edit a future next-check date for a temporary change; the edit does not create a care record.
- [ ] The MVP does not create per-plant pause/resume state or calendar-triggered seasonal suggestions.
- [ ] Custom/unlisted plants do not receive invented automatic watering schedules in the MVP.
- [ ] Plant-type context modifiers do not silently alter the MVP watering schedule.
- [ ] The optional environmental context and new symptom/specialist flows are not part of the watering release.
- [ ] Only the most recent watering record can be explicitly deleted in the MVP, with confirmation and schedule-impact handling.
- [ ] Past activity distinguishes Watered and Checked — not watered without creating a separate watering history; untouched overdue tasks do not appear in Past.
- [ ] The task and the next schedule are saved atomically.
- [ ] Undo does not remove later schedule edits or unrelated activity.
- [ ] Notifications respect existing Bloom preferences and permission behavior.
- [ ] Dynamic Type, VoiceOver, and native date controls work through the complete journey.
- [ ] Existing observation reminders and care-plan tasks continue to work independently.

## 14. Success measures

The first release should be evaluated on whether it reduces forgotten care and makes records trustworthy. Candidate measures:

- Percentage of active plants with a current watering schedule.
- Percentage of watering tasks resolved with an explicit outcome.
- Percentage of overdue tasks that are resolved within seven days.
- Percentage of watering records that distinguish watered from checked-not-watered.
- Rate of repeated immediate re-reminders after late completion (target: zero due to the scheduling rule).
- User-reported confidence in knowing what to do next.
- User-reported reduction in remembering dates across their plant collection.

Because the current app is local-only and has no analytics service, initial measurement may use local QA fixtures, manual usability sessions, and opt-in diagnostic exports rather than background event tracking.

## 15. Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Users interpret a date as proof the plant needs water | Use “Check watering” language, show soil guidance, and separate due status from the Watered action. |
| Fixed intervals cause overwatering | Start conservatively, explain the schedule, support Checked — not watered, and make adjustment easy. |
| Existing one-off reminders are confused with recurring watering | Migrate explicitly and preserve reminder kind/source; keep observation and care-plan tasks distinct. |
| Overdue tasks create guilt or notification spam | Keep overdue visible but calm, offer a direct resolution path, and suppress historical alert bursts. |
| Too much setup prevents users from adding plants | Generate a sensible default automatically; make schedule editing progressive and optional. |
| Schedule changes make history unreliable | Never rewrite past events; store scheduled-for and recorded-at separately. |
| Plant advice becomes overconfident | Use curated, reviewable profiles and plain-language caveats; do not claim diagnosis or certainty. |

## 16. Beyond watering: the broader plant-health model

Watering is the first recurring care loop, but a healthy plant may also need support across nutrition, root space, light, air, temperature, and protection from pests or disease. These areas should be added without turning Bloom into a checklist that creates unnecessary work or a diagnosis tool that claims more certainty than the evidence supports.

Bloom should treat each area as a distinct care domain with the same core loop:

> Notice a signal → inspect the relevant context → choose a conservative next step → record what happened → schedule a useful follow-up.

### 16.1 Nutrition and soil amendments

Plants may need nutrients supplied through an appropriate growing medium or fertilizer. Users may describe this as adding coco peat/coir, compost or manure, potting mix, or plant fertilizer. These materials do not all serve the same purpose:

- **Coco coir/coco peat** primarily changes the growing medium's structure and water-holding behavior; it is not a complete nutrient source by itself.
- **Compost or manure** can add organic matter and nutrients, but quality, maturity, concentration, salt content, and suitability for indoor pots vary.
- **Fertilizer** supplies selected nutrients, but the correct product, dilution, timing, and frequency depend on the plant and growing conditions.

Bloom should avoid presenting any amendment as a universal remedy. The initial nutrition feature should help the user understand what they are adding, why they are adding it, and what safe follow-up is needed.

#### Nutrition requirements

- Offer a scheduled **Feed / check nutrition** task only when the plant profile or user explicitly supports it.
- Distinguish **soil-medium change** from **nutrient feeding** in both the task and activity record.
- Capture the product or material, optional dilution/amount, date, and note without requiring a complex log.
- Warn against adding concentrated or unknown materials by guesswork.
- Show a conservative cadence based on plant type and season only when the product guidance is known; otherwise prompt the user to follow the product label.
- Avoid treating pale leaves alone as proof of nutrient deficiency. Pale leaves can also result from light, watering, roots, pests, temperature, or natural aging.
- Support a **Not sure — inspect first** outcome that does not create a feeding record.
- Never recommend manure, fertilizer, or a soil amendment as treatment for an unconfirmed infection.

#### Future nutrition experience

An eventual nutrition task could show:

1. What the user last added and when.
2. The plant profile's suggested feeding window, if available.
3. A short “before you add anything” checklist: plant condition, soil moisture, product suitability, dilution, drainage, and season.
4. Outcomes such as **Fed**, **Changed growing medium**, **Checked — no amendment**, or **Check later**.
5. A follow-up reminder that does not imply the plant's symptoms are resolved.

### 16.2 Repotting and root-space checks

Repotting moves a plant to a different container and growing medium. It may provide more root space, improve drainage, replace depleted or compacted medium, or address a root-bound plant. It is not automatically required because a plant has pale leaves, and a larger pot can increase the risk of water staying wet around the roots.

Bloom should guide users toward checking evidence before recommending a repot:

- roots circling densely or emerging from drainage holes;
- the plant drying unusually quickly despite appropriate care;
- severely compacted, degraded, or poorly draining medium;
- the plant becoming unstable or top-heavy;
- a pot that no longer supports healthy growth;
- a recent purchase or nursery medium that needs a deliberate transition.

#### Repotting requirements

- Provide a **Repot / inspect root space** care action as a guided, user-initiated task rather than an automatic response to a symptom.
- Explain that a slightly larger pot, suitable drainage, and appropriate medium matter; “bigger” is not always better.
- Capture current pot context when useful: approximate size, material, drainage, and whether roots were observed.
- Let the user record **Repotted**, **Inspected — not needed**, **Changed medium only**, or **Check later**.
- Keep repotting separate from watering history and nutrition history.
- After repotting, offer a short aftercare check-in, such as checking moisture, stability, and signs of stress; do not imply that repotting guarantees recovery.
- Avoid scheduling routine repotting too aggressively. The next prompt should be based on plant type, growth, season, and user observation rather than a universal annual rule.

### 16.3 Pests, infections, and visible plant damage

Plant owners may first notice pale or yellow leaves, leaf drop, holes or eaten leaves, spots, webbing, cotton-like clusters, visible insects, fungus-like growth, or a general decline. These are important signals but are not diagnoses. Watering, nutrition, light, temperature, humidity, root damage, pests, and disease can overlap in appearance.

Bloom should turn a symptom into a structured observation and a safe next step:

1. Identify the affected area: whole plant, leaves, stems, flowers, fruits, or pests.
2. Record the visible change in the user's words.
3. Ask only the smallest number of high-value follow-up questions needed for routing.
4. Offer possible causes as possibilities, not confirmed diagnoses.
5. Recommend inspection, isolation, environmental correction, specialist support, or a bounded first action where evidence is sufficient.
6. Schedule a comparison check when it is useful, while making clear that a completed action is not proof of recovery.

#### Suggestive diagnosis and progressive disclosure

Bloom may suggest possible causes, but it must not present a diagnosis as confirmed from a symptom, photo, or short questionnaire. The symptom experience should disclose information in stages:

1. **Record what the user noticed** using plain-language symptom choices and optional notes/photos.
2. **Check urgency** for rapid decline, widespread damage, a soft or dark stem/base, severe root concern, or heavy visible pests.
3. **Reveal a short set of possible contributors** relevant to the observed symptom, such as watering, light, temperature, nutrition, roots, pests, or disease. Do not show an exhaustive cause list by default.
4. **Offer one conservative next action**—inspect, stabilize the environment, isolate, compare later, or seek specialist help.
5. **Disclose more detail only when requested**, including why a possible cause is shown, what evidence would support it, reviewed guidance, and what would change the route.

The language should use terms such as **could**, **may**, and **possible**, for example: **“Pale leaves can have several causes. Check the soil, recent light changes, and visible pests before adding fertilizer.”** Bloom must not say **“Your plant has a nutrient deficiency”** unless a future, separately reviewed experience has evidence strong enough to support that claim.

If the symptom is outside Bloom's reviewed guidance, if evidence remains insufficient, or if the plant is worsening or shows urgent signs, Bloom should stop short of suggesting treatment and recommend consulting a plant specialist, garden centre, or appropriate local service. This specialist route is a safety boundary, not a failure state.

#### Infection and pest requirements

- Keep **symptom observation**, **possible pest**, **possible fungal/bacterial issue**, and **environmental stress** distinguishable in the data and UI even when their first step is the same.
- Use photos and notes as supporting evidence, not automatic diagnosis.
- Make “not sure” a valid outcome and route uncertain or worsening cases to inspection.
- Recommend separating a potentially affected plant from others when visible pests or contagious-looking symptoms make that prudent.
- Avoid suggesting chemical treatments, homemade mixtures, or dosage instructions without sufficiently specific evidence and reviewed guidance.
- Include escalation language for rapid decline, widespread damage, a soft or dark stem/base, severe root problems, or uncertainty that persists.
- Route symptoms outside the reviewed MVP guidance, symptoms with insufficient evidence, and worsening or urgent cases to a plant specialist rather than inventing a diagnosis or treatment.
- A plan action records what the user did; it must not mark the issue resolved. Resolution requires an explicit comparison or user decision.
- Preserve the original observation and photo when creating a follow-up plan so the user can compare like with like.

The current observation and care-plan journeys are the foundation for this domain. Their conservative behavior—inspection when evidence is missing, explicit action completion, comparison follow-up, and no automatic diagnosis—should remain the product standard as the catalog of symptoms grows.

### 16.4 Light exposure, airflow, and humidity

“Too much or too little air” is not a sufficiently precise care instruction. Bloom should separate:

- **Light exposure:** intensity, duration, direct versus indirect light, and sudden changes.
- **Air movement/ventilation:** stagnant air, poor circulation, or a location that stays damp.
- **Humidity:** air moisture, especially when relevant to a plant profile or visible symptoms.
- **Drafts and vents:** hot, cold, or drying airflow from heaters, air conditioners, fans, or windows.

#### Later environmental-release context

The later environmental release may use one optional, three-choice field rather than location permission, live weather, or a detailed room questionnaire:

**Where does this plant usually live?**

1. **Outdoor** — natural sunlight and airflow.
2. **Indoor — direct light and airflow** — typically near a bright window or glass door.
3. **Indoor — indirect light and airflow** — away from direct sunlight while still receiving indoor air movement.

The field is optional and can be skipped; it does not need a separate **Not sure** choice. This keeps the setup low-friction while still capturing useful context when the user knows it. The labels are user-observed environment categories, not precise measurements: outdoor placement does not guarantee healthy sunlight or airflow, and indoor placement does not prove a specific light level or air quality. Bloom must not infer humidity, temperature, or plant health from the selected option.

For the later environmental release, this context can be displayed in plant details and inform an on-demand growing-condition check. It is not part of the watering release, does not silently modify watering intervals, trigger weather-based reminders, request device location permission, or create separate light/air schedules.

#### Environment requirements

- Let users record the three-choice growing-location context in the later environmental release without requiring location permission or live weather data.
- Provide a simple **Check growing conditions** task in the later environmental release when a plant's profile or an observation makes it relevant.
- Ask for focused context only when it helps a care decision: direct light/air context, heater/AC draft, stagnant area, temperature exposure, or unknown.
- Recommend gradual changes rather than abrupt moves when a plant may be stressed by a light transition.
- Avoid prescribing misting as a universal humidity solution; explain that it may not meaningfully change ambient humidity and can leave foliage wet.
- Keep location, light, and airflow observations editable from plant details and link them to the relevant care record.
- Do not infer a precise light or humidity measurement from a photo.

#### Decision rationale: environmental context

Options considered:

1. **Use device location and live weather** to infer climate and watering conditions.
2. **Collect detailed environmental inputs** such as exact light direction, humidity, airflow, room, and temperature.
3. **Collect a small optional plant-location context** through progressive disclosure: indoor/outdoor, near window/glass door, and direct sunlight and/or direct air.

The MVP chooses **option 3**, refined to one optional field with three choices. Device location and live weather could provide useful context but introduce privacy, permission, network, and seasonal-model complexity. A detailed questionnaire or repeated **Not sure** branches would increase setup friction and ask users for precision they may not have. The three choices capture the user's useful mental model in one step, while keeping the data descriptive rather than pretending to measure conditions.

The **direct light and airflow** labels are intentionally low-friction context signals, not claims that the two conditions are equivalent, measured, or always beneficial. If a user reports a problem, Bloom can later ask a focused follow-up about drafts, heat, cold, humidity, or excessive sun.

### 16.5 Temperature stress

Extreme heat, cold, rapid temperature changes, and hot/cold drafts can affect plant growth and cause leaf damage or decline. Temperature should be treated as an environmental check, not as a single universal threshold across all plants.

#### Temperature requirements

- Include temperature context in the growing-conditions check: cold window, heater/AC draft, heat source, outdoor transition, or unknown.
- Use plant-profile guidance where available and phrase thresholds as approximate safe ranges, not guarantees.
- Encourage moving a plant away from direct drafts or sudden exposure before recommending more invasive treatment.
- Distinguish a temporary exposure event from an ongoing location problem.
- Offer a follow-up observation after an environmental change.
- Do not claim that temperature caused a symptom unless the user has enough evidence; retain it as a possible contributing factor.

### 16.6 Cross-symptom triage

The same visible symptom can be caused by more than one care domain. Bloom should avoid presenting five independent remedies for one symptom, which would increase cognitive overhead and encourage users to change everything at once.

For an observation such as pale leaves or leaf drop, the first screen should prioritize:

1. **Urgency:** Is the plant rapidly declining, collapsing, or showing severe damage?
2. **Evidence:** What changed, where, and when? Are pests, wet roots, dry soil, drafts, or unusual light visible?
3. **Low-risk next step:** inspect, isolate, stabilize conditions, or record a comparison.
4. **One change at a time:** avoid adding fertilizer, repotting, moving locations, and changing watering all at once unless urgent guidance requires it.
5. **Follow-up:** when should the user compare the same area again, and what would mean they should seek more help?

The product should prefer a clear inspection task over a confident but weakly supported treatment. Multiple possible causes may be shown, but the primary action should remain singular and understandable.

#### Urgency levels and escalation

Bloom should classify symptom situations into three user-facing levels:

1. **Monitor** — mild, isolated, or stable changes. Continue with observation and the normal follow-up path.
2. **Check soon** — several affected leaves, visible insects or webbing, slowly spreading symptoms, or environmental stress that should be checked soon. Keep the user in the regular observation/care-plan journey.
3. **Get plant-care help** — rapid decline or collapse, a soft/mushy or dark stem/base, severe or widespread damage, major root or drainage concern, heavy pest presence, worsening despite a reasonable first step, or a case outside Bloom's safe reviewed guidance. Offer the specialist route as the primary next action.

Only **Get plant-care help** interrupts the normal care flow. **Monitor** and **Check soon** remain calm guidance states and must not use emergency language. “Urgent” means that delaying or experimenting with unsupported treatments could increase the risk of serious damage; it does not mean that every visible symptom is an emergency.

The urgent route should preserve the user's observation and photos, explain why specialist help is suggested, and avoid presenting an unverified diagnosis. It should not require the user to complete a long questionnaire before reaching help guidance.

#### Decision rationale: symptom routing

Options considered:

1. **Symptom-first routing** — map each symptom directly to a dedicated remedy.
2. **Cause-first diagnosis** — ask many questions and select the most likely cause.
3. **Suggestive, conservative triage with progressive disclosure** — record the symptom, check urgency, show a small set of possible contributors, offer one safe next action, and refer to a plant specialist when the case is outside reviewed guidance or remains uncertain.

The MVP chooses **option 3**. Direct symptom-to-remedy routing is too confident because the same symptom can have multiple causes. A broad diagnostic questionnaire creates friction and can still produce false certainty. Progressive disclosure keeps the initial decision simple while allowing users to understand more when needed. Specialist referral provides a clear boundary for symptoms, treatments, and urgency that Bloom cannot responsibly cover in the MVP.

This decision means Bloom is an assistant for observation and next-step selection, not an automated plant diagnostician. It must preserve uncertainty, avoid unsupported chemical or homemade treatments, and never imply that completing one suggested action proves recovery.

#### Decision rationale: urgency and interruption

Options considered:

1. **No urgency levels** — treat every symptom through the same observation flow.
2. **Many detailed urgency levels** — create separate escalation behavior for each symptom and severity combination.
3. **Three levels with one interruptive route** — Monitor, Check soon, and Get plant-care help.

The MVP chooses **option 3**. A single path for every symptom can delay help for rapid decline, while many severity states add cognitive load and make ordinary plant stress feel like an emergency. Three labels communicate priority simply; only the specialist-support state interrupts the normal flow.

The specialist route is deliberately evidence- and risk-based rather than diagnosis-based. Bloom can say that the situation needs expert help without claiming to know the exact disease, pest, or cause.

## 17. Care-domain roadmap

The broader care system should be delivered in stages so Bloom earns trust through the watering loop before adding more recurring obligations.

### Phase 1 — Watering foundation (MVP)

- Type-based watering schedules.
- Due, Today, Upcoming, and Overdue states.
- Watered and Checked — not watered outcomes.
- Actual-event-based next scheduling and reliable history.

### Phase 2 — Environmental checks (post-MVP)

- Light, airflow, humidity, temperature, and growing-location observations.
- Guided environment changes with comparison follow-up.
- Plant-detail summaries for current environment context.

### Phase 3 — Nutrition and repotting (post-MVP)

- Distinct feed, medium-change, and repot actions.
- Product/material notes and conservative, profile-aware timing.
- Root-space inspection and aftercare follow-up.

### Phase 4 — Symptom and protection system (post-MVP)

- Structured symptom observations and better cross-domain triage.
- Pest and infection routing with reviewed sources.
- Isolation, specialist escalation, and comparison plans.

Each later phase must reuse the same activity model, explicit outcomes, local persistence, notification preferences, accessibility rules, and Undo/correction expectations established by watering.

#### Decision rationale: next care capability and scope control

Options considered:

1. **Add all major care domains after watering** — launch nutrition, repotting, environmental care, symptoms, pests, and pruning together.
2. **Add another set of recurring schedules** — create separate reminders for light, humidity, temperature, nutrition, and repotting.
3. **Add lightweight on-demand environmental checks first** — keep watering as the only recurring care system and defer higher-risk domains.

The product chooses the narrowed form of **option 3**: keep watering as the only MVP care system, then add lightweight environmental checks in a later release. Adding every care domain at once would increase setup work, notification volume, feed density, and content-maintenance risk before Bloom has proven its core watering loop. Creating several new recurring schedules would make users manage Bloom instead of relying on it.

The later environmental release may provide a single on-demand **Check growing conditions** flow for light, airflow, drafts, temperature context, and recent location changes. It will record observations and connect to existing symptom/care-plan guidance without creating separate recurring schedules. This is not part of the watering MVP or its immediate implementation phase.

The following remain out of scope for the watering MVP and the first implementation phase:

- Nutrition schedules, fertilizer or manure recommendations, coco coir guidance, nutrient-deficiency treatment, and dosage instructions.
- Automatic repotting reminders, pot-size predictions, and root-space schedules.
- Broad infection or pest diagnosis, fungus classification, new specialist-routing UI, and treatment recommendations from symptoms alone. Existing observation and care-plan compatibility remains available.
- Pruning and grooming schedules or growth-form recommendations.

This scope preserves one complete and understandable care loop before Bloom adds more obligations:

> Schedule → check → act → record → adjust → remind again

The decision can be revisited after watering usability and reliability are validated. Additional domains should first be introduced as focused records or guided checks, not automatically as parallel recurring schedules.

## 18. Product decision log

This log makes the product reasoning behind the watering foundation explicit for future product, design, engineering, and case-study review. Each decision records the problem being resolved, meaningful alternatives, the selected approach, why it was selected, and what it deliberately excludes. The detailed requirements above remain the source of implementation behavior; this section is the concise decision index.

### D1 — Watering profile format

- **Question:** Should Bloom use one fixed interval, a user-chosen range, or a bounded range with an automatic starting value?
- **Options considered:** Fixed interval per plant; ask the user to choose within a range; bounded range with a deterministic starting value.
- **Decision:** Use bounded ranges with deterministic starting values for the four existing catalog plants only.
- **Why:** Fixed intervals imply false precision. Asking users to choose adds setup friction and transfers a horticultural decision to them. A deterministic value keeps setup automatic and behavior testable, while the range communicates variation and later user adjustment preserves control.
- **Scope consequence:** No broad plant catalog or complex personalization is required for the watering MVP.

### D2 — First task after adding a plant

- **Question:** Should the first check be immediate, based on last watering, or delayed for the full interval?
- **Options considered:** Due today for every plant; calculate from a supplied last-watered date; wait the full starting interval.
- **Decision:** Use the known last-watered date when available; otherwise create a check for today to establish a baseline.
- **Why:** Known history should be useful, but a new user should not wait weeks before Bloom provides value. A baseline check is safer than inventing a date and more useful than silently waiting.
- **Scope consequence:** Last-watered date is optional; setup must not become a long questionnaire.

### D3 — Follow-up after checking without watering

- **Question:** Should a non-watering check use the normal interval or a shorter follow-up?
- **Options considered:** Always use the normal interval; always use a shorter interval; choose based on observed condition.
- **Decision:** Use a 3-day follow-up, editable from 2–5 days, when soil is dry or the plant needs attention. Use the normal plant interval when soil is damp and the plant appears healthy. Unknown conditions use the normal interval unless the user explicitly chooses otherwise.
- **Why:** A universal interval can be too slow for a concerning plant; an always-short interval creates unnecessary reminders. Evidence-based branching keeps urgency proportional without treating “not watered” as failure.
- **Scope consequence:** The outcome requires condition context, but Bloom must not infer urgency from missing information.

### D4 — Temporary schedule changes

- **Question:** Should the MVP support per-plant pause/resume and seasonal interval suggestions?
- **Options considered:** Add pause/resume state; add calendar-triggered seasonal suggestions; keep schedules active and use explicit next-date editing only.
- **Decision:** Keep both pause/resume and seasonal suggestions out of the MVP. A schedule remains active; temporary changes use explicit future next-check editing from schedule details.
- **Why:** Pause/resume adds schedule states, reasons, resume choices, notification cancellation/restoration, and backlog rules. Seasonal suggestions add calendar-triggered behavior and another source of unexplained schedule changes. Explicit editing solves the immediate need with fewer concepts and fewer edge cases.
- **Scope consequence:** Untouched tasks remain overdue, no pause state is persisted, and no seasonal suggestion is generated. Pause/resume and seasonal guidance remain post-MVP opportunities.

### D6 — Growing-context modifiers

- **Question:** Should pot size, light, room, drainage, medium, or placement modify schedules now?
- **Options considered:** Use them in the MVP; collect and silently apply them; keep them out of schedule calculation until later.
- **Decision:** Keep schedule modifiers and environmental context out of the watering release. Existing plant details may remain available, but only the supported plant type and explicit next-date edits determine MVP schedule timing.
- **Why:** Combining several variables makes setup and behavior harder to explain, test, and trust. Required context would increase friction; hidden context would create unexplained schedule changes.
- **Scope consequence:** Any future schedule modifier must identify the signal used, explain the suggestion, and require explicit acceptance. It should begin with one or two signals, not a large adaptive model. The three-choice location context belongs to the later environmental release.

### D7 — Correcting a mistaken past record

- **Question:** Should a mistaken watering record be edited, corrected with a second record, or deleted?
- **Options considered:** Edit in place; add a correction record; delete the mistaken record.
- **Decision:** Use explicit deletion for the local-only MVP, with confirmation, schedule-impact explanation, and immediate Undo where practical.
- **Why:** Correction records preserve an audit trail but introduce a second record concept. In-place edits are less transparent. Deletion is the simplest mental model for a user correcting an accidental entry.
- **Scope consequence:** Deletion must preserve unrelated records and later schedule changes, recalculate `Last watered`, and restore or recalculate the affected schedule without pretending the deleted event happened. Revisit this if sync, sharing, compliance, or immutable analytics are introduced.

### D8 — Watering activity history

- **Question:** Should Past show every watering outcome, only watering events, or use a separate history?
- **Options considered:** Show both completed outcomes in Past; show only Watered; create a separate watering history.
- **Decision:** Show Watered and Checked — not watered in the existing Past feed, using progressive disclosure. Untouched overdue tasks are not activity records.
- **Why:** Showing only Watered loses the meaningful distinction between watering and a deliberate non-watering check. A separate history creates another navigation destination. Compact rows and five recent records keep the distinction without exposing unnecessary complexity on the default screen.
- **Scope consequence:** Untouched overdue tasks and schedule configuration events stay out of Past; deleted records disappear from Past. Revisit grouping/filtering before creating a parallel history system if the feed becomes dense.

### D9 — Next care capability and scope

- **Question:** What should follow watering: all care domains, multiple recurring schedules, or a focused environmental check?
- **Options considered:** Add nutrition, repotting, symptoms, pests, and pruning together; create separate recurring schedules for each; add lightweight on-demand growing-condition checks first.
- **Decision:** Keep watering as the only care system in the MVP. Defer the on-demand Check growing conditions flow, nutrition, repotting, broad infection/pest diagnosis, and pruning to later releases.
- **Why:** Adding all domains increases setup effort, notifications, feed density, content risk, and diagnosis risk. Multiple schedules make users manage Bloom instead of relying on it. Environmental checks provide useful, lower-risk support and build on existing observation flows without creating new obligations.
- **Scope consequence:** The watering release has no new environmental setup or symptom/specialist UI. Later releases can add focused environmental observations and higher-risk domains after watering is validated.

### D10 — Environmental context and progressive disclosure

- **Question:** How much location and environmental context should Bloom collect without sensors, live weather, or device location access?
- **Options considered:** Use device location and live weather; ask a detailed progressive questionnaire with Not sure branches; collect one small optional three-choice plant-location context.
- **Decision:** Use one optional field with three choices: Outdoor; Indoor — direct light and airflow; Indoor — indirect light and airflow. The user can skip the field instead of choosing a separate Not sure option.
- **Why:** Device location and live weather add privacy, permission, network, and seasonal-model complexity. Detailed questions and repeated uncertainty branches increase friction. Three choices capture the user's useful mental model in one step without pretending to measure light, air, humidity, or temperature.
- **Scope consequence:** The context is descriptive and optional. It is shown in plant details and can inform future on-demand guidance, but it does not silently modify watering schedules or create environmental reminders. Drafts, heat, cold, humidity, and problematic airflow remain focused observations when needed.

### D11 — Symptom routing and suggestive diagnosis

- **Question:** How should Bloom route symptoms when the same sign can have multiple causes?
- **Options considered:** Map each symptom directly to a remedy; run a broad cause-first diagnostic questionnaire; use suggestive, conservative triage with progressive disclosure.
- **Decision:** Record the user's observation, check urgency, show a short list of possible contributors, offer one safe next action, and disclose more detail only when requested. Use tentative language rather than confirmed diagnoses.
- **Why:** Direct remedies are too confident, while broad diagnosis flows create friction without eliminating uncertainty. Progressive disclosure keeps the initial choice simple and lets users understand possible causes without overwhelming them.
- **Safety boundary:** When a symptom is outside reviewed MVP guidance, evidence is insufficient, the plant is worsening, or urgent signs are present, stop short of treatment and refer the user to a plant specialist, garden centre, or appropriate local service.
- **Scope consequence:** Bloom supports observation, conservative next steps, and comparison—not automatic diagnosis. Specialist referral is an intentional safety route, not an error state.

### D12 — Symptom urgency and interruption

- **Question:** Which signs should interrupt the normal care flow?
- **Options considered:** Treat all symptoms the same; create many symptom-specific urgency levels; use three broad levels with one interruptive specialist route.
- **Decision:** Use **Monitor**, **Check soon**, and **Get plant-care help**. Only Get plant-care help interrupts the normal flow.
- **Why:** A uniform flow can delay support for rapid decline, while many levels overwhelm users and overstate ordinary plant stress. Three broad levels provide a clear priority model without making every symptom feel urgent.
- **Escalation examples:** Rapid decline/collapse, soft or dark stem/base, severe or widespread damage, major root or drainage concern, heavy pest presence, worsening after a reasonable first step, or a case outside reviewed guidance.
- **Scope consequence:** Bloom preserves the observation and explains the referral, but does not diagnose or require a long questionnaire before recommending specialist help.

### D13 — Remove deferred activity from the MVP

- **Question:** Should a watering task include a Check later/deferred outcome?
- **Options considered:** Keep Watered, Checked — not watered, and Check later; allow a deferred activity with rescheduling; keep only the two completed care outcomes and let untouched tasks remain overdue.
- **Decision:** Remove Check later, deferred activity records, and task rescheduling from the watering MVP. A task has two completion outcomes: Watered or Checked — not watered.
- **Why:** Deferral adds a third outcome, another history type, new date semantics, notification transitions, and a distinction between not checking, checking without watering, and intentionally changing a schedule. The core MVP is clearer when a task is either completed or remains open as Overdue.
- **Scope consequence:** No deferred outcome exists in the watering data model or Past feed. Users who need a temporary timing change use explicit next-check editing from schedule details. This decision can be revisited after the two-outcome loop is validated.

### Decision-making pattern

Across these decisions, Bloom consistently prefers:

1. One clear primary task over several simultaneous obligations.
2. Explicit user choices over silent schedule changes.
3. A conservative inspection or check over unsupported diagnosis or treatment.
4. Trustworthy records that distinguish what the user actually did.
5. Progressive disclosure over exposing every option at the primary decision point.
6. Small, testable product rules before adaptive personalization.

These principles explain why the product starts with one complete watering loop and adds other care domains gradually.

## 19. Open questions for the next PRD revision

1. **Decided:** use a bounded range with a deterministic starting value for the four catalog plants. The PRD records the fixed-interval, user-chosen-range, and bounded-range alternatives and the rationale for selecting the bounded range.
2. **Decided:** use a hybrid first-task rule. Use the user's last-watered date when provided; otherwise create a check for today to establish a baseline. The PRD records why this is preferable to always using today or waiting the full interval.
3. **Decided:** use a shorter follow-up after **Checked — not watered** when the soil is dry or the plant needs attention. Start at 3 days, allow 2–5 days, use the normal interval when the soil is damp and the plant is healthy, and avoid inferring urgency from unknown conditions. The PRD records the normal, always-short, and condition-based alternatives.
4. **Decided:** keep per-plant pause/resume and seasonal interval suggestions out of the MVP. Keep schedules active and use explicit future next-check editing for temporary changes. The PRD records the pause, seasonal-suggestion, and explicit-editing alternatives.
5. **Decided:** keep interval editing, environmental context, and all schedule modifiers out of the watering release. Only supported plant type and explicit next-date edits determine MVP schedule timing.
6. **Decided:** use explicit deletion for mistaken past watering records, limited to the most recent watering record in the MVP. Do not add correction records or silent in-place edits; confirm the impact, recalculate the remaining state, preserve unrelated activity, and offer immediate Undo where practical.
7. **Decided:** show Watered and Checked — not watered in the existing Past feed, using progressive disclosure. Untouched overdue tasks do not appear in Past. Keep the default feed to five compact records and defer new watering-specific filters/search.
8. **Decided:** keep watering as the only care system in the MVP. Defer environmental checks, nutrition, repotting, broad infection/pest diagnosis, and pruning to later releases.
9. **Parked:** nutrition is out of scope. Material options and source selection remain exploratory until nutrition and repotting become active roadmap items.
10. **Parked:** environmental inputs, symptom routing, and specialist escalation are later-release decisions. The current watering release adds no environmental setup or new symptom UI.

## 20. Implementation readiness notes

The product direction is decided for the smallest credible watering MVP. The following items remain implementation/content decisions, not unresolved product questions:

- **Custom-plant handling:** save custom plants without an automatic watering schedule and show **Set up watering schedule**. Do not define or invent a fallback interval in the watering release.
- **Date/time semantics:** use the device-local calendar and the existing default reminder time. Preserve full timestamps for history and accessibility while using concise dates in the interface.
- **Unresolved task behavior:** an untouched task remains visible as Overdue and does not create an activity record. Explicit next-date editing is the MVP route for changing future task timing; interval editing and pause/resume are post-MVP.
- **Schedule migration:** map existing ordinary soil-check reminders into the new schedule only when their meaning is known. Preserve observation reminders and care-plan tasks as separate records; do not reinterpret them as watering events.
- **Atomic writes:** save the outcome, schedule transition, last-watered update, and notification synchronization as one recoverable operation, with visible failure feedback.
- **Notification behavior:** schedule only future watering checks, honor the global preference and permission state, remove stale requests after transitions, and never replay overdue history as a notification burst.
- **Content review:** version the four plant profiles. Symptom/escalation guidance and the specialist route are later-release content, not part of the watering release. Product content changes must not silently rewrite a user's schedule or history.

These notes should be resolved in the implementation plan or content review before the corresponding feature is built. They do not reopen the product decisions recorded in Section 18.

## 21. Final MVP scope decisions

The following six cuts are now part of the smallest credible watering MVP. Each preserves the core care loop while removing a secondary state, content dependency, or history edge case.

### Decision A — Support only the four known catalog plants

**Decision:** Defer automatic watering schedules for custom/unlisted plants. Keep custom plants addable, but show an explicit **Set up watering schedule** state instead of inventing a fallback interval.

**Why:** The four profiles have reviewed ranges and deterministic values. A custom fallback would require another content decision and could appear more authoritative than it is. This keeps the MVP's schedule behavior explainable.

### Decision B — Edit the next date, not the interval

**Decision:** For the first implementation, allow users to edit only the next-check date. Keep per-plant interval editing for a later release.

**Why:** Interval editing affects every future task and adds profile-versus-user interval rules, validation, and schedule recalculation. A next-date edit solves travel or temporary timing needs with one explicit action. The tradeoff is less personalization, which is acceptable for the smallest credible MVP.

### Decision C — Do not add new Past filters

**Decision:** Reuse the existing Past feed and five-record limit. Defer new watering-specific filters and search changes until the feed shows a real density problem.

**Why:** Watering records already have clear labels. New filters add UI, state, and testing without improving the primary watering loop. Progressive disclosure can remain limited to the existing See all experience.

### Decision D — Keep environmental context out of the watering release

**Decision:** Move the optional three-choice plant-location field into the later environmental-check release, even though it is already simplified.

**Why:** It is low-friction, but it is not needed to schedule or complete watering. Cutting it gives the watering release one less setup field and preserves a cleaner causal story: plant type and explicit care outcomes drive the initial schedule.

### Decision E — Treat symptom guidance as existing-product compatibility only

**Decision:** Do not add new symptom triage or specialist-routing UI in the watering release. Preserve the current observation/care-plan behavior and implement the expanded suggestive-diagnosis model later.

**Why:** Symptom routing is a safety-sensitive content domain and is not required to validate watering. Deferring new guidance reduces review, escalation, and content-maintenance work.

### Decision F — Simplify deletion dependencies

**Decision:** In the first implementation, allow deletion only for the most recent watering record. Older watering records remain unchanged.

**Why:** Reconstructing schedules across arbitrary historical deletions is complex and risks changing later user decisions. A constrained deletion flow retains the simple UX while reducing data-integrity edge cases.

### Suggested smallest credible MVP

These six cuts are now part of the smallest useful release. Keep F as an implementation safeguard even though the product continues to call the action Delete record.

The resulting scope is:

- Four known plant profiles only.
- One active watering schedule per plant.
- Watered or Checked — not watered.
- Overdue persistence.
- Explicit next-date editing only; interval editing is post-MVP.
- Existing global notifications.
- Existing Past activity with concise watering records.
- No deferred outcome, pause/resume, seasonal suggestions, custom-plant schedule, interval editing, new environmental setup, new symptom diagnosis, or new history filters.

## 22. MVP positioning and user value

### MVP definition

The smallest credible Bloom MVP is a focused watering assistant for the four supported catalog plants:

- Snake Plant
- Monstera
- Rubber Plant
- Pothos

For each supported plant, Bloom provides one active watering schedule using its plant-type profile, bounded check-in range, and deterministic starting interval. The schedule is a reminder to inspect the plant, not an instruction to water on a date.

### In scope

The watering MVP includes:

- Type-based watering profiles for the four supported catalog plants.
- A hybrid first check: use a known last-watered date when provided; otherwise create a baseline check for today.
- Due today, Upcoming, and Overdue task states.
- Two explicit outcomes:
  - **Watered**
  - **Checked — not watered**
- Optional soil-condition context during a watering check.
- A shorter 3-day follow-up, adjustable from 2–5 days, when the soil is dry or the plant needs attention.
- The normal plant-profile interval when the soil is damp and the plant appears healthy.
- Next-check scheduling from the actual recorded care event.
- Explicit next-check-date editing for temporary timing changes.
- Existing global notification preferences and future-task notifications.
- Existing Activity → Past history for Watered and Checked — not watered.
- Deletion of only the most recent watering record, with confirmation and schedule-impact handling.
- Local persistence, migration-safe existing garden data, atomic writes, Undo where safe, and native accessibility behavior.

Custom or unlisted plants remain addable, but do not receive an invented automatic watering schedule. They show **Set up watering schedule** instead.

### Explicitly out of scope

The watering MVP does not include:

- Automatic watering schedules for custom or unlisted plants.
- Per-plant pause/resume.
- Seasonal or calendar-triggered schedule suggestions.
- Per-plant interval editing.
- Deferred or **Check later** outcomes.
- A separate watering-history area.
- New watering-specific Past filters or search.
- Environmental context such as indoor/outdoor placement, light, airflow, humidity, or temperature.
- Live weather, device location, or sensor data.
- Nutrition, fertilizer, compost/manure, coco coir, or soil-amendment guidance.
- Repotting reminders or root-space predictions.
- New symptom-diagnosis or specialist-routing UI.
- Pruning or grooming schedules.

These exclusions are intentional. They reduce schedule states, notification edge cases, setup friction, content risk, migration complexity, and data-integrity risk while the core watering loop is validated.

### Product USP

Bloom's unique value is an **explainable, plant-aware watering assistant that adapts to what the owner actually did—not only to what was scheduled**.

Positioning statement:

> Bloom helps plant owners remember what to check, record what actually happened, and receive the next useful watering reminder without false precision or unnecessary complexity.

Bloom is not merely answering **“When should I water?”** It is answering:

> **Which plant should I check, what happened when I checked it, and when should I look again?**

The USP has three connected parts:

1. **Plant-aware, not generic:** the initial schedule is based on the supported plant type rather than one generic repeating reminder.
2. **Reality-aware, not calendar-blind:** Bloom distinguishes Watered from Checked — not watered and anchors the next check to the actual recorded event.
3. **Low cognitive overhead:** Bloom avoids making users manage multiple care schedules, complex setup, ambiguous deferral states, silent seasonal changes, or unsupported diagnosis.

The core loop is:

> **Check → choose Watered or Checked — not watered → Bloom schedules the next check.**

### Target user

The primary target user is:

> A person with several indoor plants who wants healthy plants but does not want to remember a separate routine for each one.

This may include:

- A beginner with a few common houseplants.
- A busy professional who forgets care dates.
- Someone who has previously overwatered or underwatered plants.
- Someone who wants practical guidance without managing a complex plant-management system.

The user does not need expert horticultural knowledge. They need a trustworthy, low-effort way to know which plant to check and how to record the result.

### User value

Without Bloom, the user must remember:

- Which plant was last watered.
- Which plants need attention.
- Whether a late task should reset the schedule.
- Whether not watering should count as a meaningful care action.
- Whether a plant that is due actually needs water.

With Bloom:

1. The user adds a supported plant.
2. Bloom creates a reasonable starting schedule.
3. The user sees the plant under Upcoming or Overdue.
4. The user checks the plant.
5. The user records what actually happened.
6. Bloom updates the next check and preserves the history.

Bloom reduces memory work without taking away the user's judgment.

### Value proposition in concrete terms

Bloom creates value in four specific ways:

1. **Memory relief:** the user no longer has to remember which of several plants needs attention or when it was last checked.
2. **Decision support:** the user gets a plant-type starting point and a clear prompt to inspect, without being told to water blindly.
3. **Accurate care memory:** Bloom records the difference between watering and checking without watering, so the history remains useful.
4. **Less repeated effort:** after a late or non-watering check, Bloom calculates the next useful check from the actual event instead of making the user reconstruct the schedule manually.

The value is not simply the presence of a reminder. It is the combination of **remembering, contextualizing, recording, and recalculating** in one small loop. Each part removes a different source of cognitive overhead:

| User problem | Bloom value | Evidence in the MVP |
| --- | --- | --- |
| “I have forgotten which plant needs attention.” | Prioritized, plant-specific task list | Upcoming, Today, and Overdue states |
| “I do not know whether the date means I should water.” | A check prompt rather than a watering command | Soil check and explicit outcome choice |
| “I watered some plants but only checked others.” | Trustworthy distinction between care outcomes | Watered versus Checked — not watered records |
| “I missed a task and do not know when to start again.” | Schedule recovery based on what actually happened | Actual-event-based next check |
| “Reminders are becoming another chore.” | A deliberately small, explainable care loop | Four profiles, two outcomes, no parallel care schedules |

### Value boundaries

Bloom's promise is intentionally limited. The MVP does not promise that a plant will stay healthy, that a reminder predicts moisture perfectly, or that Bloom can diagnose a problem. It promises to make the next watering check easier to remember and the user's care history easier to trust.

This boundary is part of the value: Bloom helps the user make a better-informed care decision without pretending to replace observation or expertise.

### Example user journey

A user has a Snake Plant and a Pothos:

1. The Snake Plant receives a 21-day starting check interval.
2. The Pothos receives a 14-day starting check interval.
3. The user forgets the Pothos and Bloom keeps it visible as Overdue instead of silently moving it.
4. The user checks the Pothos several days later and finds the soil damp.
5. The user chooses **Checked — not watered**.
6. Bloom records the decision, leaves Last watered unchanged, and schedules the next normal check.

The user does not receive a false watering history or an immediate duplicate reminder. Bloom remembers the schedule while the user remains responsible for observing the plant.

### Case-study framing

The strongest product story is not that Bloom is a complete plant-care platform. The MVP deliberately narrows a broad plant-health problem into one trustworthy behavior:

> **Help a plant owner check the right plant, record the real outcome, and know what to do next.**

This framing demonstrates deliberate product prioritization:

- A broad problem was reduced to one complete care loop.
- False precision was avoided by treating dates as check-in prompts.
- User judgment was preserved through explicit outcomes.
- History was made trustworthy by separating Watered from Checked — not watered.
- Scope was reduced by deferring pause/resume, seasonal logic, environmental context, symptoms, nutrition, repotting, and additional plant types.
- The MVP has measurable behavior before broader care capabilities are introduced.

Future capabilities should extend this loop only after the watering experience is understandable, dependable, and low-friction.

### Does this MVP make sense to build?

Yes—but it should be treated as a **focused validation MVP**, not as proof that Bloom has solved plant care.

The MVP is worth building because it has:

- A specific, recurring user problem: remembering what to do for several plants.
- A clear hypothesis: a plant-aware check-in and outcome loop can reduce memory work without encouraging blind watering.
- A bounded audience and content model: four supported plant types with reviewed starting profiles.
- A complete behavior that can be observed end to end: schedule → check → record → next check.
- A deliberately small scope that makes failures diagnosable.
- Clear decisions about what not to build, reducing the risk of mistaking feature volume for product value.

The MVP should not yet claim that it improves plant health, prevents plant loss, increases retention, or creates business impact. Those are validation questions. The first release should establish whether users understand the distinction between a check and watering, complete the task, trust the next date, and feel that Bloom reduces remembering work.

The build decision is therefore:

> **Build the reduced MVP to validate the care loop and the value proposition. Expand only after usability and behavioral evidence support the next capability.**

### Case-study evidence plan

The case study should show the work as a decision-making story, not only as a collection of polished screens. This follows the Nielsen Norman Group guidance in [“5 Steps to Creating a UX-Design Portfolio”](https://www.nngroup.com/articles/ux-design-portfolios/) (Rachel Krause, 4 August 2019), which emphasizes showing the opportunity, the designer's role, the process, rejected directions, outcomes, and learnings.

#### 1. Problem and hypothesis

Show:

- The everyday memory problem for people caring for multiple plants.
- Why generic reminders and rigid dates are insufficient.
- The hypothesis that a plant-aware **check → outcome → next check** loop can reduce cognitive overhead while preserving user judgment.
- The constraints: local-only iOS app, four known plant profiles, no live weather, no diagnosis, and a deliberately reduced MVP.

Evidence to collect:

- Short user interviews or discovery conversations about forgotten, late, or mistaken watering.
- Existing-app observations or usability issues that support the problem.
- A concise problem statement and success hypothesis before implementation.

#### 2. Role and collaboration

Document who did what rather than implying that the interface appeared fully formed. Record:

- Product framing and prioritization.
- UX flow and interaction decisions.
- Content and plant-profile research.
- Visual/UI design and accessibility decisions.
- SwiftUI implementation and persistence work.
- Testing, critique, or collaboration with developers, product partners, or plant-care reviewers, if applicable.

If one person owns several roles, state that clearly. If a decision was made without a formal collaborator or study, label it as a product judgment rather than user evidence.

#### 3. How the solution evolved

Show the progression from the broad plant-health idea to the reduced MVP:

1. Broad scope: watering, nutrition, repotting, symptoms, light, air, and temperature.
2. First product model: a general plant-care assistant.
3. Scope review: multiple schedules and diagnosis features risked cognitive overload and unsupported certainty.
4. Final MVP: four plant profiles, two outcomes, overdue persistence, actual-event-based next scheduling, and explicit next-date editing.

Use the decision log to explain why each cut was made. Include early flow sketches, content tables, alternate task models, or screenshots where available—not only the final interface.

#### 4. How the solution addresses the problem

Validate the central claims with observable tasks:

- Can a user add a supported plant and understand the starting schedule?
- Can a user tell that a due date means **check**, not automatically **water**?
- Can a user choose Watered versus Checked — not watered without hesitation?
- Can a user find an overdue plant and understand what to do next?
- Does the user trust that a late completion creates a sensible next check?
- Does Past history accurately communicate what happened?

Record task completion, misunderstandings, hesitation, quotes, and follow-up feedback. Screenshots demonstrate the interface; task evidence demonstrates whether the interface solved the intended problem.

#### 5. Challenges and directions not pursued

The case study should explicitly show the alternatives that were rejected:

- Generic recurring reminders.
- A single fixed interval for every plant.
- User-selected intervals during setup.
- Check later/deferred activity.
- Per-plant pause/resume.
- Seasonal automatic or suggested changes.
- Interval editing in the MVP.
- Automatic schedules for custom plants.
- Environmental setup in the watering release.
- New symptom diagnosis and specialist-routing UI.
- New activity filters and a separate watering history.
- Arbitrary historical deletion and schedule reconstruction.

For each major cut, explain the tradeoff: lower friction, fewer state transitions, less notification complexity, safer content boundaries, or more reliable history. Showing what is not in the product is important evidence of prioritization.

#### 6. User and product impact

Initial impact should be measured honestly and at the level the MVP can support:

- Percentage of supported plants with a schedule.
- Completion rate for watering checks.
- Rate at which users distinguish Watered from Checked — not watered.
- Overdue-task resolution within seven days.
- Number of immediate duplicate reminders after late completion; target is zero.
- User-reported confidence in knowing what to do next.
- User-reported reduction in remembering dates.

Because Bloom is local-only and currently has no analytics service, use usability sessions, manual QA fixtures, opt-in diagnostic exports, and structured feedback. Do not invent business results. If no business metric exists, say so and describe the product proxy being used.

#### 7. What was learned

After validation, record:

- Which parts of the two-outcome model users understood immediately.
- Whether “check” language prevented blind watering.
- Whether overdue tasks felt useful or judgmental.
- Whether users trusted actual-event-based scheduling.
- Whether the four-plant limitation blocked adoption.
- Which deferred capability users requested first, and why.
- Which assumptions were wrong.

Every future revision should connect to a validated learning rather than adding a feature because it was listed in the roadmap.

#### Case-study honesty rule

Separate these three categories in the final case study:

- **Observed:** supported by user behavior, testing, or recorded feedback.
- **Designed:** a deliberate product decision made from principles, constraints, or expert guidance.
- **Planned:** a future hypothesis that has not yet been validated.

This distinction keeps the case study credible. The PRD currently documents many strong design decisions, but those decisions should not be presented as user research findings until they are tested.

### How future revisions unlock more potential

The MVP is intentionally a foundation rather than the complete product. Its main strategic value is that it creates reusable primitives for future care:

- A plant has a profile, a current task, a recorded outcome, and a next action.
- The user can distinguish a planned check from care that was actually performed.
- The app can preserve an observation and connect it to a follow-up.
- The product can add guidance without silently changing a user's history.
- Activity, notifications, persistence, accessibility, and Undo provide shared infrastructure for later care domains.

Future revisions can unlock more potential in stages:

#### Revision 1 — More supported plant types

Add additional reviewed plant profiles once the four-plant model is stable. This expands the addressable audience without changing the core interaction. Each new type should have a reviewed range, deterministic starting value, care cue, and versioned content.

#### Revision 2 — Environmental context and checks

Add the deferred three-choice location context and on-demand growing-condition checks for light, airflow, drafts, and temperature. This helps users investigate why a watering routine may not be enough, without immediately creating another recurring schedule.

#### Revision 3 — Nutrition and repotting

Add distinct records for feeding, growing-medium changes, and repotting only after reviewed guidance is ready. The existing outcome-and-history model can prevent these actions from being conflated with watering or presented as universal remedies.

#### Revision 4 — Suggestive symptom guidance

Add progressive, non-diagnostic symptom routing using the existing observation and care-plan foundation. Possible causes can be shown as suggestions, while urgent or out-of-scope cases can be referred to a plant specialist. The MVP's trust boundary—do not claim certainty—remains intact.

#### Revision 5 — Controlled personalization

Use repeated outcomes and optional environmental context to suggest schedule changes, but only with explanation and explicit acceptance. The current MVP's stable schedule and clean history provide the baseline needed to evaluate whether personalization actually reduces effort rather than adding noise.

#### Revision 6 — Broader household support

Once individual care history is reliable, Bloom could support richer history, shared plant responsibility, exports, and optional household reminders. These should come after the single-user loop is trustworthy because collaboration multiplies correction, notification, and ownership complexity.

Each revision should answer a specific user problem, reuse the established care loop, and earn its complexity through demonstrated value. Future capability is not a reason to expand the MVP early; the MVP's purpose is to create a dependable foundation that makes later expansion safer and more useful.

## 23. Future opportunity areas

Once watering is reliable, Bloom can expand the same “suggest → act → record → adjust” loop to:

- light and placement checks;
- fertilizing schedules;
- repotting and seasonal tasks;
- plant-specific observation prompts;
- adaptive intervals based on repeated outcomes;
- household sharing and reminders;
- optional weather or climate context with explicit consent;
- richer plant-care history and export.

The following are explicitly post-MVP opportunities rather than watering-MVP behavior:

- per-plant pause/resume for travel, dormancy, or temporary care changes;
- seasonal interval suggestions or calendar-triggered profile adjustments;
- adaptive schedule modifiers based on environment, pot size, or repeated outcomes.

These opportunities should not be added until the watering loop is understandable, dependable, and low-friction.
