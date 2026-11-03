# Bloom

A focused native SwiftUI iOS app for intentional plant care: **notice → act → check improvement**. Add your plants, check their soil or record a change, choose what to do, and keep a useful history. Waiting counts as care, too.

Install full Xcode and an iOS Simulator runtime, then run `./Scripts/run-ios-simulator.sh` to build, boot **iPhone 17**, install Bloom and launch it. To use a different installed iPhone simulator, pass its exact device name, for example `./Scripts/run-ios-simulator.sh "iPhone 16"`. You can also open **Bloom.xcodeproj**, select the shared **Bloom** scheme and an installed iPhone Simulator, then press **⌘R**. Requires iOS 18 or later. No packages, accounts, or API keys are needed. A physical iPhone requires your development team in Signing & Capabilities.

## MVP scope

- **My plants:** Home shows the full collection count and two complete plant cards initially; when there are more than two, part of the next card peeks in to signal horizontal browsing. Tapping a card opens that plant; accessibility text sizes stack the cards vertically. **See all** opens the searchable collection. When there are no plants, Home focuses on the centered **Add plant** card. Once the first plant is added, Activity → Upcoming / Past stays visible, including helpful empty states when there are no tasks or records.
- **Add a plant:** the outlined plus in the populated Home header and My plants toolbar has the accessible label **Add plant**. On an empty Home, the centered card is the only add action. Search, choose from the local catalog or enter any name, then continue to a compact identity summary. **Add details** discloses optional photo, placement, room, and first impression fields. Saving is immediately available; unknown details stay unset and can be completed later in **Edit plant**.
- **Check and decide:** record soil and whether you watered, waited, or will check later on one screen. Save becomes available when both are chosen. Saving returns directly to the previous screen with brief confirmation and Undo; there is no separate receipt page.
- **Observe and find next steps:** tap a photographed area card, choose a single visible-change card, then add optional notes/photo. **Save change** saves the record and opens a concise visual cause/first-step guide. **Add to care plan** explicitly creates planned work; it never records treatment as done. Adding the plan returns directly to the plant, where the next care task is visible. Back to plant keeps the observation without starting a plan. There is no intermediate saved receipt or plan-setup confirmation. Activity keeps guidance and editing available.
- **Care on a plant:** an active plan presents one clear next action on the plant page, with **Care plan details** as the secondary route to progress, history, and controls. Past plans share the same **Care plans** section. Optional materials, notes, dates and sources are expandable.
- **Activity → Upcoming:** all scheduled checks appear on Home, grouped into Overdue, Today, and Upcoming. Tasks retain their type: Check soil, Observe, plan Action, or progress Review. Multiple plan tasks and ordinary soil reminders coexist. A plan that needs reassessment stays visible on Home. Completing a check clears only its matching task; Undo restores it while preserving any newer reminder you chose. An overdue check never means a plant automatically needs water.
- **Activity → Past:** a native segmented control switches the same care area to the five most recent saved activities. This includes unscheduled checks, observations, and decisions to wait. Tap a record to review it, or choose **See all** for search and plant/type filters. Returning from a record preserves the Past selection. Each plant also retains its own activity archive.

Home weather, location and city shortcuts, and personalized discovery have been removed. Bloom does not request location or fetch live weather/climate data. Add plant opens directly to a small curated indoor catalog; common/scientific-name and alias search remains available, and unlisted plants can still be added by name. Photos use the native photo picker; the app does not request camera access.

The catalog has four photographed indoor species, including **Pothos**. Catalog cards show care-level and light guidance. Search checks common/scientific names and aliases, duplicates are allowed, and unlisted plants can still be added by name. Suggestions are curated indoor ideas, not live popularity, local availability, or outdoor suitability. No city, location permission, or climate lookup is used. Legacy discovery-profile data in existing gardens is decoded for compatibility but is inactive.

## Sourced leaf guidance

After **Record a change → Leaves card → Dropping leaves card → Review change → Save change**, the **What could help** page immediately explains possible causes using colored symbol cards. Users do not choose or confirm a diagnosis. A first action is shown as short visual steps, with detailed instructions under **How to do this** and sources in a separate disclosure.

**Add to care plan** works without answering questions and creates a conservative inspection task when evidence is missing. The first guidance screen has no extra check questionnaire: unknown soil, drainage, and warning signs remain unknown, so Bloom recommends inspection rather than guessing a treatment. Previously saved care-plan evidence remains attached to its observation. Higher-risk symptoms and visible pests still offer their specific help and assessment routes.

Existing saved assessments retain their supported routes. New observations without assessment evidence take the conservative inspection route; unknown details never imply watering treatment. A soft or mushy stem observation leads to prompt specialist guidance. Pest observations link to the pest assessment. Detailed action instructions also describe when to seek help if symptoms worsen. This is an offline, curated decision flow, not live internet search or automatic photo diagnosis.

A dry-root action requires choosing **Watered it** or **Didn't water** after reading the checks. Only actual watering updates watering history. New inspection plans separate soil moisture, light/temperature and leaf inspection into independent tasks. Each completion is saved separately. After the final action, Bloom offers **Schedule check-in** or **Not now**, with an editable suggested date. A new plan does not preselect a follow-up. Existing scheduled checks are preserved. Completing an action does not resolve the issue; resolution requires an explicit decision after a comparison.

Leaf guidance uses [RHS houseplant troubleshooting](https://www.rhs.org.uk/plants/types/houseplants/how-to-help-a-poorly-houseplant), [RHS leaf damage](https://www.rhs.org.uk/prevention-protection/leaf-damage-on-houseplants), [University of Maryland indoor plant problems](https://extension.umd.edu/resource/diagnose-indoor-plant-problems), [RHS water absorption](https://www.rhs.org.uk/advice/understanding-plants/how-plants-absorb-water) and [RHS Snake plant care](https://www.rhs.org.uk/plants/sansevieria/growing-guide). Checked 21 October 2026; new leaf plans carry guidance version `2026-10-24.1`; existing plans retain their original version. Similar symptoms can have several causes; three days is an editorial comparison interval, not a source-prescribed cure deadline.

## Pest remedy journey

New pest observations also open an immediate visual guide, with possible pest causes and a conservative inspection task available without identifying the pest or inventing assessment answers. The optional **Take a closer look at the pests** action opens focused checks; previously saved pest checks remain resumable. Presentation routing stays stable while those checks save.

This version also supports a focused, nonchemical indoor-mealybug journey. Cotton-like clusters in a small reachable area on indoor leaves or stems offer **Possible mealybugs**: keep the plant separate, then gently remove reachable visible insects with tweezers. The explanation states that the identification is provisional. Fine webbing, soil-only signs, outdoor placement, and uncertain evidence receive an inspection plan. Widespread symptoms receive an inspection-and-specialist plan. There is no invented confidence score, photo diagnosis, chemical recipe, or automatic escalation.

Guidance is based on [University of Minnesota Extension](https://extension.umn.edu/garden-and-home/yard-and-garden/yard-and-garden-insects/insects-on-indoor-plants) and [University of Maryland Extension](https://extension.umd.edu/resource/mealybugs-indoor-plants), checked 19 October 2026. The app displays these sources with the plan.

- Acceptance creates planned work, never a performed-treatment activity. New actions are due today rather than becoming instantly overdue.
- Each action opens instructions/materials, optional notes, Done, Skip, and Reschedule. If the user already acted, they can record an earlier completion time. Undo corrects the action and its activity together.
- Follow-up is offered after completing the final action. Three days for leaf/inspection plans and seven days for the focused mealybug plan are editable product suggestions. **Not now** leaves the actions saved without adding a review task. Existing automatic review tasks keep their original scheduling behavior. Skipping all actions requires reassessment and never starts a recovery timer.
- A progress check shows the original observation/photo and the actions actually recorded, then accepts an outcome, note, and optional comparison photo. Unclear/worse results call for reassessment, with no stronger treatment generated automatically. No visible signs does not resolve an issue until the user explicitly confirms it.
- Revised plans cancel only the previous plan's open tasks. Other issues and soil reminders stay intact. Stopping/resolving a plan preserves its activity. Plan action/progress notes can be edited; completion/outcome records are corrected with immediate Undo or a new check-in, avoiding a conflicting task state.
- Plans remain reachable from the original observation and plant details, even if no check-in is scheduled. The plan preserves a copy of the observation as its starting baseline.

## Native iOS experience

One NavigationStack connects Home, plant details and search. **Bloom** stays fixed while Home scrolls. Its leaf mark opens Preferences; the outlined plus opens Add plant when the collection is populated. With no plants, Home focuses on a single centered Add plant action. Once a plant exists, Activity → Upcoming / Past remains visible with helpful empty states when there are no tasks or records. Home shows two complete plant cards and See all opens the collection. Four shared content roles cover title, section/emphasis, body and supporting text; native navigation and grouped form headers retain iOS semantics. See **DESIGN_GUIDELINES.md** for the type, color, spacing and action rules. Primary actions use one shared teal style, secondary actions use native bordered controls, and navigational action rows have a full-width 44-point target and chevron. Disabled actions remain visible with neutral system colors. Command buttons are text-first; utility/menu icons retain their useful SF Symbols.

Bloom's colors, plant photography, neutral cards, 16-point corners, and compact blue/yellow care tags are retained. The plant-detail hero photo fills its frame edge to edge, cropping overflow without distorting the image. Directly beneath it, the plant name and scientific name share one identity block: the plant name is the heading and the italic scientific name sits immediately below it. Plants without a scientific name show no empty subtitle row. Progress and record pages use tighter section spacing and grouped metadata instead of separate rows for every detail. Progress choices use neutral unselected indicators and a green selected check/background. Completed action records explicitly say **Action completed**, which describes recorded work rather than issue resolution. Related record links share a section; reminders open a full-screen draft editor with explicit Save and Cancel. Plant cards size their details to their content without reserving an empty tag row. Collection cards show identity only; task type belongs to the blue/yellow tags in Care. Home and Activity use compact task-first rows. Interface SF Symbols share a scaled 24-point square and semibold weight, with a compact variant for inline indicators; the brand mark retains its own size. System transitions provide navigation motion; custom press/collection animations respect Reduce Motion.

## Preferences

The Bloom logo at the top left opens a native grouped **Preferences** menu. The main plant, search, observation, and care navigation remain intact.

Preferences focuses on care notifications, default reminder time, data/privacy, and sourced care guidance. The task-notification toggle lives directly in Preferences. The reminder-time editor is labelled **Default reminder time**. Permission recovery appears inline when needed.

- **Care notifications:** a global alert switch requests permission only when explicitly enabled. Ordinary reminders follow this preference; plan tasks can additionally opt into alerts individually. Muting removes pending alerts while preserving tasks, dates, plan-level alert choices, and history. Re-enabling restores only future alerts; overdue tasks never produce a notification burst. System permission is read again when the app becomes active. If iOS denies access, an Open iOS Settings action is available. Notification scheduling errors are separate from storage failures.
- **Default reminder time:** 09:00 device-local time for new soil/observation reminders, with a native time picker and Save/Cancel. The reminder editor offers concise 3-day and 1-week shortcuts; existing tasks, chosen dates, and treatment-specific automatic review intervals are preserved. DST handling uses the device calendar.
- **Data & privacy:** read how local data, selected photos, and optional alerts work.
- **About Bloom:** updated explanation of the curated care-plan POC, guidance source links, and actual bundle version. The sample-only start-fresh control remains available with its existing confirmation.

Preferences use the same atomic garden writes as plants. Older files decode without rewriting on read. Legacy discovery data is retained but ignored. New settings preserve the previous garden, with notification test doubles isolating scheduler/permission checks from the live app. No appearance themes, automatic watering schedules, generic treatment intervals, marketing alerts, accounts, or sync controls are added.

## Data and permissions

Plants, photos, setup choices, records, care plans, independent tasks, and reminder dates are stored locally using atomic writes and visible errors. Existing gardens are preserved. The optional sample garden starts with five plants and five labeled example activities; real gardens never receive sample plants.

Ordinary reminders and plan tasks are saved in-app independently of notification permission. Enable **Preferences → Task notifications** to request iOS alert access. New gardens start with alerts off; older gardens retain their existing global alert preference. Ordinary scheduled checks follow the global preference; plan tasks additionally require **Reschedule or set notification → Notify me**. Denying access keeps tasks saved, without repeated permission requests when adding reminders. Choose **3 days**, **1 week**, a custom date/time, or turn a reminder off. Notification taps route to the relevant plant check or the exact independent plan task. Observation reminders retain their original observation instead of following the newest issue on that plant. Physical-device notification delivery/tap routing still needs verification. Automatic species identification, disease diagnosis, cloud sync, and community services are outside this MVP.

## Verification

See **Verification/Results.txt** for completed build and test results. Run the XCTest model tests and XCUITest journeys in Xcode with **⌘U**. UI tests use an isolated in-memory sample garden, preserving your saved garden and avoiding notification requests. Native screen captures are in **Previews**.

Use Xcode’s `BloomTests` and `BloomUITests` targets to verify this revision. The older standalone programs under `Verification/` are retained as historical reference; their model-only compile commands no longer include the app’s native feedback dependencies.

## Source files

- `BloomApp.swift`: app entry, error presentation, notification routing.
- `Models.swift`: models, storage, care completion/Undo, reminders, task date grouping.
- `AppPreferencesModels.swift`: persisted app preferences, local reminder-time defaults, and injectable notification access/scheduling.
- `PreferencesView.swift`: native grouped settings, task notifications, reminder-time editor, data/privacy, and sourced guidance.
- `NativeComponents.swift`: native actions, form treatment, footers.
- `DesignSystem.swift`: colors, typography, cards, tags, activity rows.
- `GardenViews.swift`: onboarding, Home, collection, plant details/editing.
- `CarePlanModels.swift`: assessment evidence, sourced steps, care plans, independent tasks, and outcomes.
- `CarePlanStore.swift`: plan acceptance, completion/Undo, follow-up scheduling, reassessment, exact task notifications, and cleanup.
- `CareGuidanceViews.swift`: saved-observation entry and pest assessment, explained recommendation, and explicit acceptance.
- `LeafCareModels.swift`: bounded leaf checks, conservative recommendation rules, sourced instructions and compatible progress outcomes.
- `LeafCareViews.swift`: leaf/pest routing, visual cause cards, conservative first actions, focused safety paths and follow-up.
- `CarePlanViews.swift`: plan progress, baseline, rescheduling, stopping/resolution, and notes.
- `PlanTaskViews.swift`: action instructions, completion, comparison, Undo, and optional notifications.
- `CareFeed.swift`: native Tasks/Activity switch, grouped tasks, recent records, and connected record navigation.
- `AddPlantFlow.swift`: search → compact identity and optional details → plant detail.
- `PlantDiscovery.swift`: neutral search field, catalog cards, and add-by-name search results.
- `PlantSearchModels.swift`: catalog search and alias matching; legacy profile decoding and recent-search compatibility.
- `PlantSetupViews.swift`: room presets.
- `CareViews.swift`: soil checks, saved state, reminders, history, comparisons.
- `ObservationViews.swift`: plant-specific area/change cards and optional context; successful saves transition directly to guidance and return to the plant without a receipt page.

## Original Figma references

- [Lo-fi flow](https://www.figma.com/design/n3dPoS2OakACxSrkbu8cfW/Plant-care-app---Bloom?node-id=2469-8834)
- [Observation journey](https://www.figma.com/design/n3dPoS2OakACxSrkbu8cfW/Plant-care-app---Bloom?node-id=2400-15956)
- [User journey](https://www.figma.com/design/n3dPoS2OakACxSrkbu8cfW/Plant-care-app---Bloom?node-id=2176-11493)
- [Intentional care journey](https://www.figma.com/design/n3dPoS2OakACxSrkbu8cfW/Plant-care-app---Bloom?node-id=2281-13369)
- [Design system](https://www.figma.com/design/n3dPoS2OakACxSrkbu8cfW/Plant-care-app---Bloom?node-id=2340-14608)

Figma files were not modified. Their visual roles are implemented with reusable SwiftUI components.

## Audit refinements

The 24 October audit preserves Bloom’s palette and native behavior. Plant identity appears once in the hero; navigation says Plant. Editing shows the plant type as read-only and allows photo, placement, room/location, initial condition, light, and drainage updates through a restricted save that preserves name, type, species, reference asset, watering history, and current reminders. Tapping the portrait opens a full-screen viewer with Change photo. Removal uses a centered native alert and named feedback. Care owns Remind me; Recent activity owns See all. Known catalog species have a Wikipedia reference. Area cards use real plant-part photography. Unknown custom plants invite an actual photo rather than showing an invented species.

The audit raised ambiguity between duplicate plants. Duplicates remain allowed and are distinguished by their saved location and care history. This is recorded audit feedback, not evidence from a new user-research study.

## Photography

The Pothos photo in the asset catalogue is by Cindy Christian, via [NC State Extension Plant Toolbox](https://plants.ces.ncsu.edu/plants/epipremnum-aureum/), used under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/), cropped to fit. Credits are also available under Preferences → Care guidance & sources. Previously saved Pothos plants without an asset continue to show this reference photo; user-selected photos take priority. No garden-data migration is needed for these interface changes.


## Interactive-demo flow alignment — 25 October 2026

The native app follows the interactive demo at chandrikasanapati.me/bloom throughout the journey, rather than only its Home header. Shared SwiftUI components (`BloomContentPage`, `BloomChoiceList`, `BloomSelectionHint` and `BloomCareStepSummary`) keep the visual rules consistent.

| Journey | Native behaviour |
| --- | --- |
| Home / collection | Two complete cards initially, horizontal collection browsing, collection count, See all, Bloom logo preferences, outlined plus, task-first Upcoming rows and compact Past cards. |
| Search / browse | Direct catalog browse, common/scientific/alias search, and add-by-name for unlisted plants. Saved legacy personalization profiles are ignored. |
| Add plant | Photo/name review, visible room shortcuts, Indoor/Outdoor placement, selected-state status rows and explicit skip actions. |
| Routine care | Soil and care decision share one screen with a single Save action. Saving returns to the previous screen with brief confirmation and Undo, without an extra receipt page. |
| Reminder | “Remind about” choice, date/time, concise 3-day/week shortcuts, and Save/Cancel. Ordinary reminder alerts follow Preferences. Merely choosing a date never saves. |
| Notice a change | Real plant-part cards → visible-change cards → optional photo/note → immediate What could help. |
| Understand | Canonical care-plan title, possible-cause cards, visible step summaries/explanation and sources. Opening a saved assessment starts with guidance; questions stay optional. Existing plans offer View care plan. |
| Act | Numbered instructions, visible optional note, explicit watering decision where needed, completion, Skip/Undo, rescheduling and optional follow-up after the final action. |
| Compare | Starting observation, Better/Same/Worse/Not sure, optional note/photo, early-check protection and a dedicated Check-in saved page with review, scheduling, record and explicit-resolution actions. |
| History / settings | Home keeps five recent entries; See all searches the entire matching history. Native notification permissions, reminder defaults, privacy, source links and real photo-library controls remain functional. |

The portfolio's Home / care-journey / reset and simulated-time controls are presentation tools, not product features. Its prepared five-plant garden is not merged into someone's saved native garden. iOS navigation chrome, date pickers and permission dialogs adapt to the device; location and alerts use real native services rather than the browser's example previews.

Unanswered pest checks now allow a conservative inspection plan; heavy reported damage prioritizes specialist help without requiring every answer. Evidence required for physical mealybug removal remains unchanged. New pest plans use guidance version `2026-10-25.1`; older plans keep their evidence, tasks and recorded guidance version. No action or recovery is logged merely by accepting guidance.

The optional legacy `Plant.reminderNotifications` field remains decodable. New or edited ordinary reminders use the global notification preference and clear any old per-reminder override. Existing garden files are decoded without rewriting on read.

Older saved plant names are normalized on load: catalog plants resolve to their canonical common name from scientific species, and custom plants with a saved type retain that type. Existing garden locations, care records and reminders are preserved.
