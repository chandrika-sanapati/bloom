# Bloom MVP Implementation Plan

**Status:** Ready for phased implementation
**Product scope:** Smallest credible watering MVP
**Source of truth:** [`PRD.md`](PRD.md), especially Sections 8, 13, 18, 20, 21, and 22
**Last updated:** 14 November 2026

## 1. Purpose

This document translates the reduced Bloom MVP into an implementation sequence.

The current app is a broad plant-care prototype. We are intentionally resetting the implementation as a greenfield MVP rather than preserving the prototype's broader feature surface or saved-data compatibility.

The prototype currently contains:

- one-off plant reminders;
- soil checks and observations;
- care plans and plan tasks;
- leaf and pest guidance;
- multiple reminder types;
- notification preferences for ordinary reminders and care-plan tasks;
- history search and filters;
- location, room, light, drainage, and initial-condition details;
- sample/demo journeys and extensive UI-test fixtures.

The agreed MVP is intentionally much smaller:

> **For four supported plant types, help the user check the right plant, record Watered or Checked — not watered, and schedule the next check from what actually happened.**

The implementation should simplify the product surface by removing obsolete prototype behavior and building the smallest coherent watering product directly.

## 1.1 North-star implementation principle: simplify the experience first

The primary implementation goal is not to preserve every existing feature in the visible product. It is to create a calm, focused experience in which a plant owner can understand and complete the next watering action with minimal thought.

Every implementation decision should be tested against this question:

> **Does this make the next watering check clearer, faster, or more trustworthy?**

If it does not, it should be deferred, hidden from the primary flow, or removed from the MVP surface—even if the underlying code remains temporarily for compatibility.

### Simplification rules

- Prefer one primary action per screen.
- Prefer two clear outcomes over three or more ambiguous states.
- Prefer progressive disclosure over showing every capability at once.
- Prefer a stable active schedule over pause, seasonal, or adaptive states.
- Prefer explicit next-date editing over interval configuration in the MVP.
- Prefer a clean greenfield model over compatibility layers for deferred prototype features.
- Prefer task-first language over feature-first language.
- Do not add taglines, eyebrow text, or helper copy by default; include supporting text only when it helps the user's current decision.
- Prefer a short, complete journey over a broad but fragmented platform.
- Do not add a control merely because the existing model supports it.
- Do not keep a visible feature in the MVP only because it already exists.

### Primary experience to protect

The visible MVP should make this journey feel immediate and coherent:

1. Add one of the four supported plants.
2. Understand the starting watering check.
3. Open the task from Today, Upcoming, or Overdue.
4. Choose Watered or Checked — not watered.
5. See the next check and a trustworthy history.

Care plans, observations, symptom guidance, environmental setup, advanced schedule controls, and unrelated settings must not compete with this journey. They may remain behind compatibility boundaries until they can be intentionally redesigned or removed.

## 2. Final MVP contract

### Supported plants

Automatic watering schedules are available only for:

| Plant | Scientific name | Check-in range | Deterministic starting interval |
| --- | --- | ---: | ---: |
| Snake Plant | *Dracaena trifasciata* | 14–30 days | 21 days |
| Monstera | *Monstera deliciosa* | 7–14 days | 10 days |
| Rubber Plant | *Ficus elastica* | 7–21 days | 14 days |
| Pothos | *Epipremnum aureum* | 7–21 days | 14 days |

Custom and unlisted plants are out of the MVP catalog. The add flow should offer only the four supported plants.

### Schedule behavior

- One active watering schedule per supported plant.
- The schedule is a check prompt, not an instruction to water.
- If the user supplies a valid last-watered date, the first check is calculated from that date plus the profile interval.
- If the user does not know the date, the first check is today at the default reminder time.
- Due tasks are grouped as Today, Upcoming, or Overdue.
- An untouched task remains Overdue and does not create an activity record.
- The user can edit the next check date only.
- No per-plant pause/resume state.
- No seasonal suggestions or calendar-based changes.
- No per-plant interval editing.

### Task outcomes

The task flow has exactly two outcomes:

1. **Watered**
2. **Checked — not watered**

There is no **Check later**, deferred outcome, or task rescheduling flow.

For **Watered**:

- save a care record;
- update `Last watered`;
- resolve the current task;
- schedule the next check from the actual watering date plus the profile interval.

For **Checked — not watered**:

- save a care-check record;
- do not update `Last watered`;
- resolve the current task;
- use the profile interval from the actual check date when the soil is damp and the plant appears healthy;
- use a 3-day follow-up, editable from 2–5 days, when soil is dry or the plant needs attention.

### Activity

The existing Past feed shows only completed watering outcomes:

- Watered
- Checked — not watered

Untouched overdue tasks and schedule configuration changes do not appear in Past. Do not add a separate watering history or new watering-specific filters/search in this implementation.

### Corrections

- Only the most recent watering record can be deleted in the MVP.
- Deletion requires confirmation.
- Deletion recalculates `Last watered` and the next check from the remaining valid state.
- Older watering records, unrelated observations, care plans, and later activity remain unchanged.
- Immediate Undo may be retained where it can be implemented safely.

### Explicitly deferred or removed

Do not add to the watering release:

- environmental context or growing-condition tasks;
- symptom diagnosis or new specialist-routing UI;
- nutrition, fertilizer, manure, coco coir, or soil amendments;
- repotting or root-space guidance;
- pruning or grooming schedules;
- custom-plant automatic schedules;
- per-plant interval editing;
- pause/resume;
- seasonal logic;
- Check later/deferred tasks;
- new Past filters/search;
- broad navigation into care plans, observations, or leaf/pest guidance.

The prototype's old care-plan, observation, discovery, and reminder data does not need to remain decodable. The greenfield MVP may use a clean data model and a clean local store.

## 3. Current implementation audit

### Current data model

Relevant existing types are in `Bloom/Models.swift`:

- `Plant.reminder: Date?` is a single one-off reminder.
- `Plant.reminderKind` supports `.soilCheck` and `.observation`.
- `Plant.reminderObservationID` connects observation reminders to observations.
- `Plant.reminderNotifications` is legacy per-reminder notification state.
- `Plant.lastWatered` exists but is not a complete schedule model.
- `CareAction` currently includes `.watered`, `.waited`, and `.postponed`.
- `CareRecord.Kind.check` can already represent a soil check.
- `CareRecord.action` stores the care outcome.
- `Garden` stores plants, records, optional care plans/tasks, legacy preferences, and app preferences.
- `PlantSpecies.catalog` already contains exactly the four supported catalog species.

### Current store behavior — to replace, not preserve

`Bloom/BloomStore` behavior is currently distributed across `Models.swift` and extensions:

- `setReminder` saves a one-off date and reminder kind; it will be replaced by watering schedule operations.
- `finishCare` handles several care domains; it will be replaced by explicit watering outcomes.
- `deleteRecord` handles broad care history; it will be replaced by most-recent watering-record deletion.
- `commit` can be retained as a small local persistence primitive, but the Garden model should be rebuilt around watering.
- Plan-task notification synchronization will be removed with the care-plan feature.

### Current UI surface

The main surface is in `GardenViews.swift`, `CareFeed.swift`, `CareViews.swift`, and `DesignSystem.swift`:

- `RootView` routes plants, history, add-plant, reminder tasks, and care-plan tasks.
- `GardenView` shows plant cards plus an Upcoming/Past `HomeCareFeed`.
- `HomeCareFeed` combines one-off plant reminders with care-plan tasks.
- `ReminderCard` and `ReminderEditorView` support soil reminders and observation-comparison reminders, including presets and Turn off.
- `PlantReminderTaskView` routes either to a soil check or observation/follow-up flow.
- `CareCheckView` currently exposes three `CareAction` choices, including the deferred/postponed path.
- `PlantDetailView` exposes Check soil, Record a change, ReminderCard, care plans, plant details, and recent activity.
- `HistoryView` exposes filters for checks, changes, follow-ups, actions, search, and plant selection.

### Current broader feature surface — remove

These files represent capabilities outside the reduced watering MVP:

- `CarePlanModels.swift`
- `CarePlanStore.swift`
- `CarePlanViews.swift`
- `PlanTaskViews.swift`
- `ObservationViews.swift`
- `CareGuidanceViews.swift`
- `LeafCareModels.swift`
- `LeafCareViews.swift`
- `PlantSetupViews.swift`
- `PreferencesView.swift` sections for broader data/guidance

These files can be deleted as part of the greenfield reset once their references are removed from the remaining MVP files. Do not retain compatibility wrappers for removed product concepts.

### Current test and fixture surface

Existing tests strongly encode the broader product:

- `BloomTests/CarePlanTests.swift`
- `BloomTests/LeafCareTests.swift`
- `BloomTests/AuditTests.swift`
- `BloomUITests/LeafCareUITests.swift`
- `BloomUITests/RemedyUITests.swift`
- portions of `BloomUITests/AuditUITests.swift`
- care-plan, observation, and reminder assertions in `BloomUITests/BloomUITests.swift`

The broader tests have already been removed. Phase 0 protection tests should now be reduced to the greenfield MVP boundary: four supported profiles, clean local persistence, schedule/record integrity, and failed-write behavior. No legacy decoding tests are needed.

## 4. Recommended architecture direction

### 4.1 Make watering first-class

Do not extend `Plant.reminder`. Replace the prototype reminder model with a first-class schedule model.

Conceptual target:

```text
WateringSchedule
- plantID
- profileID
- profileRangeDays
- profileIntervalDays
- nextCheckAt
- createdAt
- updatedAt
- defaultReminderTimeSnapshot

WateringRecord
- id
- plantID
- scheduledFor
- recordedAt
- outcome: watered | checkedNotWatered
- soilCondition: dry | damp | unknown
- note
- followUpDays: optional
```

Implementation notes:

- Use a dedicated `WateringRecord` for MVP activity; do not overload the broad prototype `CareRecord`.
- Do not persist `deferred` or `postponed` as a watering outcome.
- Do not persist `paused` or a seasonal schedule state.
- Do not persist user-adjusted interval state in the MVP.
- Store `scheduledFor` separately from `recordedAt` so late completion remains understandable.
- Keep `previousNextCheckAt` only if it is needed for safe Undo; do not build a general audit ledger.

### 4.2 Keep the greenfield model small

The MVP model should contain only plant identity, the four supported profile values, watering schedules, watering records, and notification preferences. Do not retain reminder kinds, observation IDs, care-plan IDs, leaf assessments, pest assessments, or legacy discovery fields.

### 4.3 Centralize schedule transitions

Create a small, testable schedule service or store extension with operations such as:

```text
wateringProfile(for plant) -> profile
createInitialSchedule(for plant, lastWatered: Date?)
wateringState(for plant, now: Date) -> due state
completeWateringCheck(plantID, outcome, soil, note, now)
editNextCheck(plantID, date)
deleteLatestWateringRecord(plantID)
undoWateringCompletion(receipt)
```

All of these operations must use one atomic `commit` boundary for the record and schedule transition.

Do not let views directly mutate `Plant.reminder`, `lastWatered`, or schedule-related fields.

### 4.4 Use profile content as data

Add profile metadata near `PlantSpecies` or in a dedicated model:

```text
WateringProfile
- id/scientificName
- displayName
- rangeDays
- startingIntervalDays
- careCue
```

The four profiles should be versioned content. The schedule engine should consume profile data, not hard-code plant-specific branching in SwiftUI views.

## 5. Phased implementation plan

### Phase 0 — Baseline and protection

**Goal:** Establish a safe working baseline before changing behavior.

**Status:** Complete — greenfield reset, test-scope reset, and simulator verification recorded 14 November 2026.

Tasks:

- Confirm the working tree before the reset and record the files being intentionally removed.
- Create a small greenfield fixture strategy for supported plants, watering schedules, and watering records.
- Identify the prototype model and entry points being removed rather than migrated.
- Identify all navigation entry points to observations, care plans, leaf guidance, pest guidance, and broader history filters.
- Remove obsolete prototype production files and references instead of creating a compatibility namespace.
- Remove broader product tests from the active test surface; add them back phase by phase when the corresponding capability returns.
- Remove obsolete prototype production files as part of the greenfield reset.
- Run the focused Phase 0 protection tests once the greenfield model is in place.

Deliverable:

- A verified file/symbol inventory and a greenfield fixture strategy.
- The active test surface contains only `BloomTests/Phase0ProtectionTests.swift`.
- Phase 0 tests protect the four-plant catalog boundary, clean schedule/history persistence, failed writes, and corrupt-file handling.
- No legacy observation-reminder decoding test is required because the greenfield store intentionally does not decode the prototype model.
- The empty `BloomUITests` target was removed from `Bloom.xcodeproj`; UI tests will be reintroduced when a later phase has a deliberate MVP UI journey to verify.
- Greenfield verification passed on iPhone 18 Pro Max: `Phase0ProtectionTests` executed 4 tests with 0 failures.

### Phase 1 — Profile content and schedule domain

**Goal:** Replace generic reminder assumptions with a first-class watering schedule foundation.

**Status:** Complete — greenfield watering profiles and schedule domain verified 14 November 2026.

Tasks:

- Add `WateringProfile` for Snake Plant, Monstera, Rubber Plant, and Pothos.
- Add profile range, deterministic starting interval, and care cue.
- Add a schedule representation with active status only.
- Define the catalog as the four supported plants only; remove custom/unlisted add-by-name from the MVP.
- Implement initial schedule creation using the hybrid last-watered rule.
- Implement due/today/upcoming/overdue classification.
- Keep the data model free of observation reminders and legacy reminder kinds.

Acceptance:

- A supported plant gets exactly one active schedule.
- A known last-watered date produces the expected first check.
- An unknown last-watered date produces a baseline check today.
- The add flow exposes only supported catalog plants.
- Watering schedules and records survive a clean store relaunch.
- Verification passed on iPhone 18 Pro Max: Phase 0 and Phase 1 tests executed 10 tests with 0 failures.

### Phase 2 — Watering task experience

**Goal:** Create the single primary care interaction.

**Status:** Complete — two-outcome watering task domain verified 14 November 2026.

Tasks:

- Replace the current three-choice `CareAction` UI with two choices: Watered and Checked — not watered.
- Keep soil state optional or required only if needed to determine the shorter follow-up; avoid forcing unnecessary fields.
- Remove Check later/postponed from the watering UI and watering model.
- Make copy consistently say **Check watering** or **Check soil**, never “water now” when the user has not chosen Watered.
- Add the 3-day dry/concerning follow-up with 2–5 day selection.
- Use the normal profile interval for damp/healthy checks.
- Save actual `recordedAt` and original `scheduledFor`.
- Show a compact success confirmation and safe Undo.

Acceptance:

- No watering can be recorded without an explicit Watered selection.
- Watered updates Last watered and schedules from the actual event.
- Checked — not watered never updates Last watered.
- Dry/concerning checks offer a shorter follow-up.
- Unknown/damp healthy checks do not create an unsupported diagnosis.
- No Check later or postponed choice appears.
- Verification passed on iPhone 18 Pro Max: Phase 0–2 tests executed 16 tests with 0 failures.

### Phase 3 — Home, Upcoming, and Past simplification

**Goal:** Make the MVP surface calm and task-first.

**Status:** Complete — focused Home, Upcoming, Past, catalog, and watering-check surface verified 15 November 2026.

Tasks:

- Simplify `HomeCareFeed` to watering tasks plus only the minimum existing compatibility content required by saved gardens.
- Ensure each watering task row shows plant, check action, due state/date, and watering/soil tag.
- Keep Today, Upcoming, and Overdue sections.
- Keep Past to Watered and Checked — not watered records.
- Remove new watering-specific filters/search from the MVP scope.
- Keep the existing five-record compact home history behavior.
- Remove or hide care-plan, observation, leaf, and pest actions from the watering MVP entry surface.
- Preserve direct plant detail access only if it does not introduce competing primary actions.

Acceptance:

- A user can identify the next action without understanding care plans.
- An untouched overdue task is visible in Upcoming/Overdue but absent from Past.
- Past labels clearly distinguish Watered from Checked — not watered.
- No deferred record or schedule configuration event appears in Past.
- Verification passed on iPhone 18 Pro Max: Phase 0–2 domain tests executed 16 tests with 0 failures; the Phase 3 application build also succeeded.

### Phase 4 — Plant setup and detail simplification

**Goal:** Make adding a supported plant fast and make the next watering state obvious.

**Status:** Complete — focused supported-plant setup and watering detail verified 15 November 2026.

Tasks:

- Keep the existing catalog search for the four supported plants.
- Remove custom add-by-name; the MVP catalog contains only four supported plants.
- Add optional last-watered capture without making it a blocking setup questionnaire.
- Remove environmental context questions from the watering release.
- Remove or defer optional room/light/drainage setup if it distracts from adding the plant and first schedule.
- On plant detail, prioritize identity, next check, last watered, and the Check watering action.
- Replace the generic ReminderCard with a watering-specific schedule card.
- Keep schedule editing to next-check date only.
- Make care plans, observations, and broader details unavailable from the MVP primary flow.

Acceptance:

- A supported plant can be added quickly and has a visible next check.
- Last-watered is optional and clear.
- A custom plant can be saved without receiving false watering guidance.
- Plant detail answers “what do I do next?” immediately.
- Verification passed on iPhone 18 Pro Max: Phase 0–2 tests executed 16 tests with 0 failures; the Phase 4 application build also succeeded.

### Phase 5 — Notifications and persistence hardening

**Goal:** Make the core loop dependable across relaunches and notification states.

**Status:** Complete — watering-only notification service and future/permission behavior verified 15 November 2026.

Tasks:

- Rename/refactor notification synchronization around watering tasks rather than plan tasks where appropriate.
- Schedule only future watering checks.
- Remove/update notifications after completion or next-date editing.
- Never replay overdue history as a notification burst.
- Keep global task-notification preference and default reminder time.
- Make schedule transition, record, Last watered, and notification sync failure behavior visible and recoverable.
- Reset the local greenfield store cleanly when the MVP schema changes; no prototype migration is required.
- Ensure deleting the latest watering record cannot delete later or unrelated activity.

Acceptance:

- Storage permission/error behavior leaves previous data safe.
- Relaunch preserves schedule, record, and Last watered state.
- Notification permission denial leaves in-app tasks intact.
- Date edits do not leave stale notifications.
- Overdue tasks do not produce a burst of notifications.
- Verification passed on iPhone 18 Pro Max: Phase 5 notification tests executed 3 tests with 0 failures.

### Phase 6 — UX polish and MVP validation

**Goal:** Deliver an exceptional, calm, accessible experience and collect evidence.

**Status:** Complete — focused watering UX polish and validation baseline verified 15 November 2026.

The empty Home state is the app's first screen. There is no separate start/onboarding gate; Bloom opens directly to the single **Add a plant** action.

Tasks:

- Review every watering screen against `DESIGN_GUIDELINES.md`.
- Tune hierarchy, spacing, copy, empty states, loading states, and error feedback.
- Verify Dynamic Type and VoiceOver for task rows, outcomes, dates, and selected state.
- Verify 44-point targets and native date-picker behavior.
- Add Reduce Motion-safe transitions only where they improve comprehension.
- Capture final screens plus process artifacts: early flow, discarded concepts, schedule model, and migration decision.
- Run structured usability sessions or a manual validation pass against the PRD case-study tasks.
- Record observed, designed, and planned outcomes separately.

Acceptance:

- A first-time user can complete the main watering journey without explanation.
- The user understands that due means check, not automatically water.
- The user can distinguish Watered from Checked — not watered.
- The user understands an overdue task and can resolve it.
- The app feels focused rather than like a partially hidden care platform.
- Verification passed on iPhone 18 Pro Max: build succeeded and Phase 0–2 plus Phase 5 tests executed 19 tests with 0 failures.

### Phase 7 — MVP validation and case-study evidence

**Goal:** Validate that the simplified watering loop is understandable, low-friction, and trustworthy before adding post-MVP capabilities.

**Status:** Planned.

This phase is validation work, not a feature-expansion phase. It should test the product we have before adding environmental checks, additional plant types, nutrition, repotting, or symptom guidance.

Tasks:

- Run the complete first-time journey on iPhone 18 Pro Max:
  - Start Bloom.
  - Add each supported plant type.
  - Understand the profile starting suggestion.
  - Open a Today or Upcoming task.
  - Choose Watered.
  - Confirm Last watered and the next check.
- Run the non-watering journey:
  - Open an overdue or due task.
  - Choose Checked — not watered.
  - Verify Last watered remains unchanged.
  - Verify the normal or shorter follow-up behavior is understandable.
- Validate the schedule-editing journey:
  - Edit the next check date.
  - Confirm the task moves to the expected timing group.
  - Confirm no activity record is created by schedule editing.
- Validate notification behavior:
  - Notifications disabled.
  - Permission denied.
  - Future notification enabled.
  - Overdue task with no notification burst.
- Review empty and recovery states:
  - No plants.
  - No watering history.
  - No tasks scheduled.
  - Failed save.
  - Invalid or unavailable task.
- Review accessibility:
  - Dynamic Type at large and accessibility sizes.
  - VoiceOver labels, selected state, dates, outcome choices, and save action.
  - 44-point touch targets.
  - Reduced Motion behavior.
- Capture case-study artifacts:
  - Final core-flow screenshots.
  - Early scope or flow artifacts.
  - Rejected concepts and why they were rejected.
  - Schedule/profile model.
  - Validation notes and observed friction.
- Classify findings as **Observed**, **Designed**, or **Planned**.
- Record the top usability gaps and decide whether each requires a fix, a content change, or a post-MVP decision.
- Update the PRD case-study evidence section with honest user and product impact. Do not invent business outcomes.

Validation questions:

- Does the user understand that a due date means **check**, not automatically **water**?
- Can the user distinguish Watered from Checked — not watered without explanation?
- Does the user understand what an overdue task requires?
- Does the next-check date feel trustworthy after a late completion?
- Does the user understand why the next check is shorter after a dry/concerning non-watering check?
- Does adding a supported plant feel fast enough?
- Does the Home surface feel focused rather than sparse or confusing?
- Do notifications feel helpful rather than like another schedule to manage?

Evidence to capture:

- Task completion and hesitation points.
- Misunderstood labels or dates.
- User quotes and confidence feedback.
- Accessibility findings.
- Notification and persistence issues.
- Requests for deferred capabilities, recorded as future hypotheses rather than immediate scope.

Acceptance:

- A first-time user can complete the main watering journey without facilitator explanation.
- Users understand the distinction between checking and watering.
- Users can resolve an overdue task without guessing what Bloom expects.
- Users trust the next check after on-time and late completion.
- Empty, error, permission, and disabled states are understandable.
- Dynamic Type and VoiceOver do not hide or truncate the primary action.
- Findings are documented in the PRD and case-study artifacts.
- Any post-MVP feature proposal is tied to a validated user problem.

## 6. Removal and deferral strategy

### Remove from primary UI first

The safest order is to remove entry points before deleting implementation:

1. Hide observation, care-plan, leaf, pest, and environmental entry actions from the MVP home/plant flow.
2. Replace the generic ReminderCard with the watering schedule card.
3. Remove Check later/postponed from the watering task flow.
4. Remove interval editing, pause/resume, and seasonal controls from schedule UI.
5. Remove new history filters/search from the watering surface.
6. Retain legacy views only if they are still needed to open existing records safely.

### Remove from the greenfield model

Remove these prototype concepts rather than retaining compatibility fields:

- `Plant.reminder`
- `Plant.reminderKind`
- `Plant.reminderObservationID`
- `Plant.reminderNotifications`
- `Plant.lastWatered` once derived from `WateringRecord`
- legacy `PlantSearchPreferences` and recent searches
- `CarePlan`, `PlanTask`, and related saved data
- observation and leaf/pest fields on the broad `CareRecord`
- `CareAction.postponed`

### Candidate file treatment

| Area | MVP treatment |
| --- | --- |
| `Models.swift` | Replace the broad model with the clean MVP model. |
| `CareViews.swift` | Simplify into the primary watering check and schedule UI. |
| `CareFeed.swift` | Make watering tasks and compact Past history primary. |
| `GardenViews.swift` | Simplify Home and plant detail entry points. |
| `DesignSystem.swift` | Add watering-specific task/status components; remove only unused components after migration. |
| `AddPlantFlow.swift` | Keep the four-plant catalog add flow; remove custom add-by-name and non-MVP setup prompts. |
| `PlantDiscovery.swift` | Keep only four-plant catalog search. |
| `BloomApp.swift` | Retain notification routing; simplify watering notification routes. |
| `AppPreferencesModels.swift` / `PreferencesView.swift` | Keep global notification preference and default reminder time; defer unrelated settings only if they add surface noise. |
| `CarePlan*.swift` | Delete from the MVP target. |
| `ObservationViews.swift` / `LeafCare*.swift` | Delete from the MVP target. |
| `PlanTaskViews.swift` | Delete from the MVP target. |
| `PlantSetupViews.swift` | Defer from the watering setup unless required for existing garden compatibility. |

Do not physically delete broad feature files as a first move. Deleting them can break saved gardens, tests, previews, or Xcode target references and makes rollback harder.

## 7. MVP test strategy

Tests should follow the phased implementation rather than be rewritten all at once.

### Model/store coverage

Add or update tests for:

- profile ranges and deterministic starting values;
- hybrid first check behavior;
- unsupported custom plant schedule state;
- Today/Upcoming/Overdue classification;
- Watered transition;
- Checked — not watered transition;
- dry/concerning 3-day follow-up and 2–5 day bounds;
- damp/healthy normal interval;
- late completion anchoring;
- next-date editing;
- most-recent-only deletion;
- Last watered recalculation;
- atomic failure behavior;
- notification permission denial and stale-request removal;
- legacy garden decoding.

### UI journey coverage

Prioritize:

1. Add supported plant → first schedule.
2. Add custom plant → Set up watering schedule.
3. Open Today/Upcoming task → Watered.
4. Open overdue task → Checked — not watered.
5. Dry check → shorter follow-up.
6. Edit next check date.
7. View Past record.
8. Delete most recent watering record.
9. Notification tap → matching watering task.
10. Dynamic Type and VoiceOver pass for the watering flow.

Move broader care-plan and remedy tests out of the watering acceptance gate rather than deleting them without a compatibility plan.

## 8. Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| The app still feels like the old broad care platform | Remove competing primary entry points before polishing individual watering screens. |
| Existing data is lost during migration | Preserve legacy decoding, use atomic writes, and never reinterpret observation reminders as watering events. |
| Profile intervals appear overly authoritative | Use “check-in” language, show ranges/cues, and require an explicit outcome. |
| A user cannot schedule a custom plant | Show a clear Set up watering schedule state; do not invent a fallback. |
| The two outcomes are confusing | Use distinct labels and supporting copy; never preselect Watered. |
| The MVP feels too sparse | Make the watering task, schedule card, dates, history, and feedback exceptionally clear rather than adding unrelated features. |
| Deletion changes too much history | Limit deletion to the most recent watering record and preserve older/later unrelated data. |
| Notification behavior becomes hard to trust | Keep one global preference, future-only requests, and no overdue burst. |
| Broad code removal breaks compatibility | Hide routes first; delete files only after a dedicated migration and target cleanup. |

## 9. Definition of done

The reduced MVP is ready for validation when:

- The user can add each of the four supported plants and receive the correct profile-based first check.
- A custom plant can be saved without an invented schedule.
- Home clearly prioritizes watering tasks.
- Watering has exactly two outcomes.
- Actual Watered and Checked — not watered records produce correct next checks.
- Dry/concerning checks produce the shorter follow-up.
- Late completion does not create a duplicate immediate task.
- Overdue tasks persist until completed or explicitly date-edited.
- Only the latest watering record can be deleted.
- Past history remains concise and accurate.
- Notifications follow the global preference without overdue bursts.
- Existing gardens decode and remain safe.
- The watering flow passes accessibility and Dynamic Type review.
- The case-study artifacts distinguish observed evidence from design decisions and future hypotheses.

## 10. Next implementation step

Start with **Phase 0 — Baseline and protection**, then implement **Phase 1 — Profile content and schedule domain**. Do not begin by deleting care-plan or observation files. The first code change should establish the watering profile/schedule seam and a migration-safe test fixture so later UI simplification has a stable foundation.
