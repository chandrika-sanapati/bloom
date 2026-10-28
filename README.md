# Bloom

A focused native SwiftUI iOS app for intentional plant care: **notice → act → check improvement**. Add your plants, check their soil or record a change, choose what to do, and keep a useful history. Waiting counts as care, too.

Open **Bloom.xcodeproj**, select **Bloom → iPhone 17** (or another installed iPhone Simulator), then press **⌘R**. Your other Xcode projects are independent. Requires iOS 18 or later. No packages, accounts, or API keys are needed. A physical iPhone requires your development team in Signing & Capabilities.

## MVP scope

- **My plants:** Home shows the full collection count and two complete plant cards initially, with horizontal swiping to browse the rest. Tapping a card opens that plant; accessibility text sizes stack the cards vertically. **See all** opens the searchable collection. Each plant keeps its room, optional photo, starting condition, and care history.
- **Add a plant:** the same outlined plus in the Home header and My plants toolbar has the accessible label **Add plant** and opens the Add plant page with **Search plant** inside its search field. Choose from a small local catalog or enter any name, optionally attach a photo, choose its room, and record its current status. Saving opens that plant's detail page. Nothing is added until setup is saved.
- **Check and decide:** record soil as Dry, Damp, or Not sure, then record whether you watered, waited, or will check later. Saving offers Edit, Undo, an optional reminder, and Close record.
- **Observe and find next steps:** tap a photographed area card, choose a single visible-change card, then add optional notes/photo. **Save change** saves the record and immediately opens the visual cause/first-step guide with a **Change saved** notice. **Add to care plan** explicitly creates planned work; it never records treatment as done. Adding the plan returns directly to the plant, where the next care task is visible. Back to plant keeps the observation without starting a plan. There is no intermediate saved receipt or plan-setup confirmation. Activity keeps guidance and editing available.
- **Care on a plant:** the next action or progress check opens directly from the plant's Care plans section. Active plans have their own Care plans section with View care plan; past plans stay accessible. Optional materials, notes, dates and sources are expandable.
- **Activity → Upcoming:** all scheduled checks appear on Home, grouped into Overdue, Today, and Upcoming. Tasks retain their type: Check soil, Observe, plan Action, or progress Review. Multiple plan tasks and ordinary soil reminders coexist. A plan that needs reassessment stays visible on Home. Completing a check clears only its matching task; Undo restores it while preserving any newer reminder you chose. An overdue check never means a plant automatically needs water.
- **Activity → Past:** a native segmented control switches the same care area to the five most recent saved activities. This includes unscheduled checks, observations, and decisions to wait. Tap a record to review it, or choose **See all activity** for search and plant/type filters. Returning from a record preserves the Past selection. Each plant also retains its own activity archive.

Home weather and city shortcuts, the profile shortcut, the standalone Diagnosis tab, and the unconnected scanner have been removed. There is no live weather service or background weather adaptation. Optional regional climatology is used only within personalized discovery. Photos use the native photo picker; the app no longer requests camera access. The catalog is labeled **Choose a plant**, without claiming a live popularity ranking.

## Personalized plant discovery

The plus opens Add plant. **Personalize picks** keeps the saved city inside a compact search field. The location-arrow control at its right offers **Locate me**; tapping the saved city changes it, and typed searches support city/postal-code lookup. Device location is requested only after Locate me, using while-in-use access. City candidates include country/region for disambiguation. No location is required to save indoor-light and plant-type preferences.

Manual search uses [Open-Meteo / GeoNames](https://open-meteo.com/en/docs/geocoding-api). Device location uses Core Location and Apple's reverse geocoding. Only approximate coordinates (rounded to 0.1 degrees) are retained; NASA POWER requests use a coarser 0.5-degree regional grid. The user confirms Save before preferences reach the garden file. Cancelling preserves existing settings.

There are no climate or hemisphere controls. The season derives from the selected latitude and current month. Broad regional climate context is inferred from [NASA POWER monthly climatology](https://power.larc.nasa.gov/docs/services/api/temporal/climatology/) temperatures, humidity and corrected precipitation. These editorial groupings are not an official climate classification or live weather. The current rules flag cool winters when a monthly mean is below 10°C, warm/humid conditions when all monthly means are at least 18°C with mean humidity at least 60%, and dry/hot conditions when a month is at least 24°C with less than 1 mm/day precipitation; remaining complete data uses a mild grouping. Missing/invalid climatology stays unknown, with Retry; saving the city still works. Tropical monthly data uses year-round context; an unresolved location does not reuse old manual climate assumptions.

**Indoor light** uses three compact text choices: Not sure yet, Lower natural light, and Bright, indirect light. **Plant preferences** keeps smaller visual multi-select cards for Upright, Bushy, Trailing, and Climbing. Several choices are combined as alternatives, not requirements a single plant must satisfy. Leaving all clear explores all shapes. **Reset preferences** sits with the choices and clears light and plant-form selections while preserving the chosen city. **Save** is the fixed primary action. Reset edits the draft: Save applies it and Cancel restores saved choices. **Turn off personalized picks** stops using the profile while retaining it for later. Saving a revised profile turns picks back on. **Remove saved area** clears the city, coordinates, and regional climate in the draft; Save applies it and Cancel restores the saved area. Light and plant forms are retained. Matching shapes are grouped first; other shapes remain available, with care level and light needs shown on each card.

The catalog has four photographed species, including **Pothos**, so trailing/climbing preferences have a useful match. Plant-form choices also use real plant photography. Form is a growing habit, not a guarantee of a particular mature shape; some plants need support or shaping. [RHS epipremnum guidance](https://www.rhs.org.uk/plants/epipremnum/growing-guide) supports the trailing/climbing entry. Recommendations remain curated indoor ideas, not live local popularity, outdoor hardiness, availability, or guaranteed suitability.

Search checks common/scientific names and aliases across the whole catalog regardless of preferences. Ownership counts remain visible and duplicates are allowed. Submitted/selected searches stay local, deduplicated and limited to five; Clear removes them. No match offers add by name with the existing room/status flow. Nothing is added until setup is saved.

Plant-care context also uses [University of Minnesota indoor-light guidance](https://extension.umn.edu/garden-and-home/yard-and-garden/gardening-in-minnesota/lighting-for-indoor-plants), [RHS seasonal guidance](https://www.rhs.org.uk/plants/types/houseplants/winter-interest-houseplants-care), and [RHS Monstera guidance](https://www.rhs.org.uk/plants/swiss-cheese-plants/how-to-grow-swiss-cheese-plants). Sources checked 20 October 2026. Source links are available under How these picks work.

## Sourced leaf guidance

After **Record a change → Leaves card → Dropping leaves card → Review change → Save change**, the **What could help** page immediately explains possible causes using colored symbol cards. Users do not choose or confirm a diagnosis. A first action is shown as short visual steps, with detailed instructions under **How to do this** and explanations/source links under **Why this might help**.

**Add to care plan** works without answering questions and creates a conservative inspection task when evidence is missing. **I've checked my plant** is an optional disclosure for recording observations; soil choices use visual cards, drainage only appears for dry mix, and previously supplied placement is reused. These refinements save for resuming and can be cleared together. Missing answers remain unknown. Watering still requires dry mix, confirmed drainage, no reported warning signs and a supported indoor plant; other evidence-dependent actions retain conservative bounds.

For the existing indoor catalog, dry mix with drainage, soggy mix and a recent environmental change have distinct routes. Unknown species, spots, outdoors, uncertain answers and pest signs lead to inspection rather than an assumed watering treatment. Soft/dark stems or rapid decline lead to prompt specialist help, with follow-up off by default. Visible pests link to the existing pest assessment. This is an offline, curated decision flow, not live internet search or automatic photo diagnosis.

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

One NavigationStack connects Home, plant details and search. **Bloom** stays fixed while Home scrolls. Its leaf mark opens Preferences; the outlined plus opens Add plant. Home shows two complete plant cards and See all opens the collection. Four shared content roles cover title, section/emphasis, body and supporting text; native navigation and grouped form headers retain iOS semantics. See **DESIGN_GUIDELINES.md** for the type, color, spacing and action rules. Primary actions use one shared teal style, secondary actions use native bordered controls, and navigational action rows have a full-width 44-point target and chevron. Disabled actions remain visible with neutral system colors. Command buttons are text-first; utility/menu icons retain their useful SF Symbols.

Bloom's colors, plant photography, neutral cards, 16-point corners, and compact blue/yellow care tags are retained. The plant-detail hero photo fills its frame edge to edge, cropping overflow without distorting the image. Directly beneath it, the plant name and scientific name share one identity block: the plant name is the heading and the italic scientific name sits immediately below it. Plants without a scientific name show no empty subtitle row. Progress and record pages use tighter section spacing and grouped metadata instead of separate rows for every detail. Progress choices use neutral unselected indicators and a green selected check/background. Completed action records explicitly say **Action completed**, which describes recorded work rather than issue resolution. Related record links share a section; reminders open a full-screen draft editor with explicit Save and Cancel. Plant cards size their details to their content without reserving an empty tag row. Collection cards show identity only; task type belongs to the blue/yellow tags in Care. Home and Activity use compact task-first rows. Interface SF Symbols share a scaled 24-point square and semibold weight, with a compact variant for inline indicators; the brand mark retains its own size. System transitions provide navigation motion; custom press/collection animations respect Reduce Motion.

## Preferences

The Bloom logo at the top left opens a native grouped **Preferences** menu. The main plant, search, observation, and care navigation remain intact.

Plant discovery controls live in **Add plant → Personalize**, keeping the Settings menu focused. Removing the old discovery section preserves the saved city, light, plant-type choices, and personalized search behavior. The task-notification toggle lives directly in Preferences. The reminder-time editor is labelled **Reminder time**. Permission recovery appears inline when needed.

- **Care notifications:** a global alert switch requests permission only when explicitly enabled. Each ordinary reminder can also opt out of alerts without removing its task. Muting removes pending alerts while preserving tasks, dates, plan-level alert choices, and history. Re-enabling restores only future alerts; overdue tasks never produce a notification burst. System permission is read again when the app becomes active. If iOS denies access, an Open iOS Settings action is available. Notification scheduling errors are separate from storage failures.
- **Reminder time:** 09:00 device-local time for new soil/observation reminders, with a native time picker and Save/Cancel. It prefills new explicit reminders and preset day choices. Existing tasks, chosen dates, and treatment-specific automatic review intervals are preserved. DST handling uses the device calendar.
- **Data & privacy:** clear up to five recent searches with confirmation; read how local data, selected photos, city lookup, approximate regional coordinates, and optional alerts work. Clearing searches leaves plants and preferences untouched.
- **About Bloom:** updated explanation of the curated care-plan POC, guidance source links, and actual bundle version. The sample-only start-fresh control remains available with its existing confirmation.

Preferences use the same atomic garden writes as plants. Older files decode without rewriting on read. New settings preserve the previous garden, with notification test doubles isolating scheduler/permission checks from the live app. No appearance themes, automatic watering schedules, generic treatment intervals, marketing alerts, accounts, or sync controls are added.

## Data and permissions

Plants, photos, setup choices, records, care plans, independent tasks, and reminder dates are stored locally using atomic writes and visible errors. Existing gardens are preserved. The optional sample garden starts with five plants and five labeled example activities; real gardens never receive sample plants.

Ordinary reminders and plan tasks are saved in-app independently of notification permission. Enable **Preferences → Task notifications** to request iOS alert access. New gardens start with alerts off; older gardens retain their existing alert intent. Ordinary scheduled checks receive alerts unless their own Notify me choice is off, while plan tasks additionally require **Reschedule or set notification → Notify me**. Denying access keeps tasks saved, without repeated permission requests when adding reminders. Choose a preset, a custom date/time, or turn it off. Notification taps route to the relevant plant check or the exact independent plan task. Observation reminders retain their original observation instead of following the newest issue on that plant. Physical-device notification delivery/tap routing still needs verification. Automatic species identification, disease diagnosis, cloud sync, and community services are outside this MVP.

## Verification

See **Verification/Results.txt** for completed build and test results. Run the XCTest model tests and XCUITest journeys in Xcode with **⌘U**. UI tests use an isolated in-memory sample garden, preserving your saved garden and avoiding notification requests. Native screen captures are in **Previews**.

Use Xcode’s `BloomTests` and `BloomUITests` targets to verify this revision. The older standalone programs under `Verification/` are retained as historical reference; their model-only compile commands no longer include the app’s native feedback dependencies.

## Source files

- `BloomApp.swift`: app entry, error presentation, notification routing.
- `Models.swift`: models, storage, care completion/Undo, reminders, task date grouping.
- `AppPreferencesModels.swift`: persisted app preferences, shared discovery profile, local reminder-time defaults, and injectable notification access/scheduling.
- `PreferencesView.swift`: native grouped settings, location access, task notifications, reminder-time editor, data/privacy, and sourced guidance.
- `NativeComponents.swift`: native actions, form treatment, footers.
- `DesignSystem.swift`: colors, typography, cards, tags, activity rows.
- `GardenViews.swift`: onboarding, Home, collection, plant details/editing.
- `CarePlanModels.swift`: assessment evidence, sourced steps, care plans, independent tasks, and outcomes.
- `CarePlanStore.swift`: plan acceptance, completion/Undo, follow-up scheduling, reassessment, exact task notifications, and cleanup.
- `CareGuidanceViews.swift`: saved-observation entry and pest assessment, explained recommendation, and explicit acceptance.
- `LeafCareModels.swift`: bounded leaf checks, conservative recommendation rules, sourced instructions and compatible progress outcomes.
- `LeafCareViews.swift`: leaf/pest routing, visual cause cards, immediate first actions, optional resumable refinements and follow-up.
- `CarePlanViews.swift`: plan progress, baseline, rescheduling, stopping/resolution, and notes.
- `PlanTaskViews.swift`: action instructions, completion, comparison, Undo, and optional notifications.
- `CareFeed.swift`: native Tasks/Activity switch, grouped tasks, recent records, and connected record navigation.
- `AddPlantFlow.swift`: search → review/photo → room → status → plant detail.
- `PlantDiscovery.swift`: neutral search field, seasonal picks, recent searches, ownership badges, photo cards, care/light metadata.
- `PlantSearchModels.swift`: optional saved area/light preferences, hemisphere/season rules, explainable ranking, aliases and recent-query storage.
- `GrowingLocationModels.swift`: resolved city, coarse coordinates, climatology decoding, and plant-form metadata.
- `GrowingLocationService.swift`: city search, climate lookup, bounded/cancellable Core Location, and reverse geocoding.
- `PlantPreferenceArtwork.swift`: photographic plant-form choices and reusable indoor-light artwork.
- `PlantSearchPersonalizationView.swift`: inline location search, compact light choices, visual multi-select plant forms, and draft Reset.
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

The 24 October audit preserves Bloom’s palette and native behavior. Plant identity appears once in the hero; navigation says Plant. Editing shows a read-only Plant type and a separate Nickname field. It changes nickname, photo, placement, light and drainage through a restricted update that preserves type, species, reference asset, room, starting condition, watering history and current reminders. Tapping the portrait opens a full-screen viewer with Change photo. Removal uses a centered native alert and named feedback. Care owns Remind me; Recent activity owns See all. Known catalog species have a Wikipedia reference. Area cards use real plant-part photography. Unknown custom plants invite an actual photo rather than showing an invented species.

The audit raised ambiguity between duplicate plants. Duplicates remain allowed, with nickname guidance during setup. This is recorded audit feedback, not evidence from a new user-research study.

## Photography

The Pothos photo in the asset catalogue is by Cindy Christian, via [NC State Extension Plant Toolbox](https://plants.ces.ncsu.edu/plants/epipremnum-aureum/), used under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/), cropped to fit. Credits are also available under Preferences → Care guidance & sources. Previously saved Pothos plants without an asset continue to show this reference photo; user-selected photos take priority. No garden-data migration is needed for these interface changes.


## Interactive-demo flow alignment — 25 October 2026

The native app follows the interactive demo at chandrikasanapati.me/bloom throughout the journey, rather than only its Home header. Shared SwiftUI components (`BloomContentPage`, `BloomChoiceList`, `BloomSelectionHint` and `BloomCareStepSummary`) keep the visual rules consistent.

| Journey | Native behaviour |
| --- | --- |
| Home / collection | Two complete cards initially, horizontal collection browsing, collection count, See all, Bloom logo preferences, outlined plus, task-first Upcoming rows and compact Past cards. |
| Search / personalize | Compact white personalization entry, photographic catalogue/form choices, room-light preferences, optional real city location, reset beside the choices and fixed Save. |
| Add plant | Photo/name review, visible room shortcuts, Indoor/Outdoor placement, selected-state status rows and explicit skip actions. |
| Routine care | Soil choice → recorded decision → saved receipt, with fixed primary actions and visible selection hints. Close record returns to the caller. |
| Reminder | Task kind, date/time, draft-only 3-day/week presets, optional per-reminder notifications and Save/Cancel. Merely choosing a preset never saves. |
| Notice a change | Real plant-part cards → visible-change cards → optional photo/note → immediate What could help. |
| Understand | Canonical care-plan title, possible-cause cards, visible step summaries/explanation and sources. Opening a saved assessment starts with guidance; questions stay optional. Existing plans offer View care plan. |
| Act | Numbered instructions, visible optional note, explicit watering decision where needed, completion, Skip/Undo, rescheduling and optional follow-up after the final action. |
| Compare | Starting observation, Better/Same/Worse/Not sure, optional note/photo, early-check protection and a dedicated Check-in saved page with review, scheduling, record and explicit-resolution actions. |
| History / settings | Home keeps five recent entries; See all searches the entire matching history. Native notification permissions, reminder defaults, privacy, source links and real photo-library controls remain functional. |

The portfolio's Home / care-journey / reset and simulated-time controls are presentation tools, not product features. Its prepared five-plant garden is not merged into someone's saved native garden. iOS navigation chrome, date pickers and permission dialogs adapt to the device; location and alerts use real native services rather than the browser's example previews.

Unanswered pest checks now allow a conservative inspection plan; heavy reported damage prioritizes specialist help without requiring every answer. Evidence required for physical mealybug removal remains unchanged. New pest plans use guidance version `2026-10-25.1`; older plans keep their evidence, tasks and recorded guidance version. No action or recovery is logged merely by accepting guidance.

The optional `Plant.reminderNotifications` field preserves legacy alerts when absent. Muting one reminder preserves its date/task and other alerts; global muting preserves that local choice. Existing garden files are decoded without rewriting on read.

The optional `Plant.typeName` preserves a custom plant’s original type independently of its nickname. Existing catalog plants resolve their type from species without a migration; a legacy custom plant’s current type is preserved on its next explicit edit.
