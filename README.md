# Bloom

A focused native SwiftUI iOS app for intentional plant care: **observe → understand → choose a care plan → act → compare**. Add your plants, check their soil or record a change, choose what to do, and keep a useful history. Waiting counts as care, too.

Open **Bloom.xcodeproj**, select **Bloom → iPhone 17** (or another installed iPhone Simulator), then press **⌘R**. Your other Xcode projects are independent. Requires iOS 18 or later. No packages, accounts, or API keys are needed. A physical iPhone requires your development team in Signing & Capabilities.

## MVP scope

- **My plants:** Home shows the full collection count and a horizontal row of plant cards. A partial next card signals scrolling; tapping a card opens that plant. **See all** opens the searchable collection. Each plant keeps its room, optional photo, starting condition, and care history.
- **Add a plant:** a labelled **＋ Add plant** button sits directly below the cards inside My plants and opens Search plants. Choose from a small local catalog or enter any name, optionally attach a photo, choose its room, and record its current status. Saving opens that plant's detail page. Nothing is added until setup is saved.
- **Check and decide:** record soil as Dry, Damp, or Not sure, then record whether you watered, waited, or will check later. Saving offers Edit, Undo, an optional reminder, and Done.
- **Observe and find next steps:** record a change and optional photo/context. The saved observation offers **Find next steps**. Answer focused questions, read an explained recommendation with sources, then explicitly choose whether to start a care plan. Closing the assessment keeps the observation and answers; no plan is started until acceptance.
- **Care → Tasks:** all scheduled checks appear on Home, grouped into Overdue, Today, and Upcoming. Tasks retain their type: Check soil, Observe, plan Action, or progress Review. Multiple plan tasks and ordinary soil reminders coexist. A plan that needs reassessment stays visible on Home. Completing a check clears only its matching task; Undo restores it while preserving any newer reminder you chose. An overdue check never means a plant automatically needs water.
- **Care → Activity:** a native segmented control switches the same care area to the five most recent saved activities. This includes unscheduled checks, observations, and decisions to wait. Tap a record to review it, or choose **See all activity** for search and plant/type filters. Returning from a record preserves the Activity selection. Each plant also retains its own activity archive.

Home weather and city shortcuts, the profile shortcut, the standalone Diagnosis tab, and the unconnected scanner have been removed. There is no live weather service or background weather adaptation. Optional regional climatology is used only within personalized discovery. Photos use the native photo picker; the app no longer requests camera access. The catalog is labeled **Choose a plant**, without claiming a live popularity ranking.

## Personalized plant discovery

Add plant opens Search plants. **Personalize picks** keeps the saved city inside a compact search field. The location-arrow control at its right offers **Locate me**; tapping the saved city changes it, and typed searches support city/postal-code lookup. Device location is requested only after Locate me, using while-in-use access. City candidates include country/region for disambiguation. No location is required to save indoor-light and plant-type preferences.

Manual search uses [Open-Meteo / GeoNames](https://open-meteo.com/en/docs/geocoding-api). Device location uses Core Location and Apple's reverse geocoding. Only approximate coordinates (rounded to 0.1 degrees) are retained; NASA POWER requests use a coarser 0.5-degree regional grid. The user confirms Save before preferences reach the garden file. Cancelling preserves existing settings.

There are no climate or hemisphere controls. The season derives from the selected latitude and current month. Broad regional climate context is inferred from [NASA POWER monthly climatology](https://power.larc.nasa.gov/docs/services/api/temporal/climatology/) temperatures, humidity and corrected precipitation. These editorial groupings are not an official climate classification or live weather. The current rules flag cool winters when a monthly mean is below 10°C, warm/humid conditions when all monthly means are at least 18°C with mean humidity at least 60%, and dry/hot conditions when a month is at least 24°C with less than 1 mm/day precipitation; remaining complete data uses a mild grouping. Missing/invalid climatology stays unknown, with Retry; saving the city still works. Tropical monthly data uses year-round context; an unresolved location does not reuse old manual climate assumptions.

**Indoor light** uses three compact text choices: Not sure yet, Lower natural light, and Bright, indirect light. **Plant preferences** keeps smaller visual multi-select cards for Upright, Bushy, Trailing, and Climbing. Several choices are combined as alternatives, not requirements a single plant must satisfy. Leaving all clear explores all shapes. A fixed **Reset preferences** action clears light and plant-form choices together while preserving the chosen city. Reset edits the draft: Save applies it and Cancel restores saved choices. **Turn off personalized picks** stops using the profile while retaining it for later. Saving a revised profile turns picks back on. **Remove saved area** clears the city, coordinates, and regional climate in the draft; Save applies it and Cancel restores the saved area. Light and plant forms are retained. Matching shapes are grouped first; other shapes remain available, with light suitability explained on each card.

The catalog has three photographed species and an illustrated **Pothos** option, so trailing/climbing preferences have a useful match. Form is a growing habit, not a guarantee of a particular mature shape; some plants need support or shaping. [RHS epipremnum guidance](https://www.rhs.org.uk/plants/epipremnum/growing-guide) supports the trailing/climbing entry. The illustration is labelled. Recommendations remain curated indoor ideas, not live local popularity, outdoor hardiness, availability, or guaranteed suitability.

Search checks common/scientific names and aliases across the whole catalog regardless of preferences. Ownership counts remain visible and duplicates are allowed. Submitted/selected searches stay local, deduplicated and limited to five; Clear removes them. No match offers add by name with the existing room/status flow. Nothing is added until setup is saved.

Plant-care context also uses [University of Minnesota indoor-light guidance](https://extension.umn.edu/garden-and-home/yard-and-garden/gardening-in-minnesota/lighting-for-indoor-plants), [RHS seasonal guidance](https://www.rhs.org.uk/plants/types/houseplants/winter-interest-houseplants-care), and [RHS Monstera guidance](https://www.rhs.org.uk/plants/swiss-cheese-plants/how-to-grow-swiss-cheese-plants). Sources checked 20 October 2026. Source links are available under How these picks work.

## First remedy journey

This version supports a focused, nonchemical indoor-mealybug journey. Cotton-like clusters in a small reachable area on indoor leaves or stems offer **Possible mealybugs**: keep the plant separate, then gently remove reachable visible insects with tweezers. The explanation states that the identification is provisional. Fine webbing, soil-only signs, outdoor placement, and uncertain evidence receive an inspection plan. Widespread symptoms receive an inspection-and-specialist plan. There is no invented confidence score, photo diagnosis, chemical recipe, or automatic escalation.

Guidance is based on [University of Minnesota Extension](https://extension.umn.edu/garden-and-home/yard-and-garden/yard-and-garden-insects/insects-on-indoor-plants) and [University of Maryland Extension](https://extension.umd.edu/resource/mealybugs-indoor-plants), checked 19 October 2026. The app displays these sources with the plan.

- Acceptance creates planned work, never a performed-treatment activity. New actions are due today rather than becoming instantly overdue.
- Each action opens instructions/materials, optional notes, Done, Skip, and Reschedule. If the user already acted, they can record an earlier completion time. Undo corrects the action and its activity together.
- Follow-up is optional. Seven days for the focused mealybug plan and three days for an inspection are editable product defaults for checking evidence, not evidence of a cure or pesticide retreatment intervals. Expert-support plans default to no automatic follow-up. The automatic check-in is scheduled only after the actions are accounted for and at least one was actually completed, measured from the latest recorded completion. Skipping every action starts no false recovery timer. An extra early check-in does not consume the automatic check after the remaining actions.
- A progress check shows the original observation/photo and the actions actually recorded, then accepts an outcome, note, and optional comparison photo. Unclear/worse results call for reassessment, with no stronger treatment generated automatically. No visible signs does not resolve an issue until the user explicitly confirms it.
- Revised plans cancel only the previous plan's open tasks. Other issues and soil reminders stay intact. Stopping/resolving a plan preserves its activity. Plan action/progress notes can be edited; completion/outcome records are corrected with immediate Undo or a new check-in, avoiding a conflicting task state.
- Plans remain reachable from the original observation and plant details, even if no check-in is scheduled. The plan preserves a copy of the observation as its starting baseline.

## Native iOS experience

One NavigationStack provides a single Home and pushed detail/search pages. There is no bottom tab bar or separate bell destination. A horizontal plant row sits above a native Tasks/Activity segmented control. Forms, grouped Lists, Pickers, Menus, DatePickers, confirmation dialogs, PhotosPicker, and ShareLink use native behavior. Typography uses system text styles and icons use SF Symbols. Primary buttons are native bordered-prominent buttons tinted in Bloom teal. The Bloom header stays fixed while Home scrolls. Preferences are available from its gear. The collection owns its labelled Add plant action; there is no floating Home button. The full collection also retains a labelled Add plant toolbar action. Empty collections offer Add a plant in their empty state.

Bloom's colors, plant photography, neutral cards, 16-point corners, and compact blue/yellow care tags are retained. A plant card shows a task tag only when it has a scheduled check. System transitions provide navigation motion; custom press/collection animations respect Reduce Motion.

## Preferences

The Home gear opens a native grouped **Preferences** menu. The main plant, search, observation, and care navigation remain intact.

- **Plant discovery:** Personalized picks on/off; Your growing space with a saved-city/light/type summary; Location access with actual iOS permission status and a link to iOS Settings when applicable. Settings and Search plants edit the same persisted profile. Search reuses a saved city without requesting GPS. Turning picks off retains the profile and makes discovery generic. Locate me is always explicit; there is no automatic or background location refresh. A city can remain saved after device access is revoked.
- **Care notifications:** a global alert switch requests permission only when explicitly enabled. Muting removes pending alerts while preserving tasks, dates, plan-level alert choices, and history. Re-enabling restores only future alerts; overdue tasks never produce a notification burst. System permission is read again when the app becomes active. If iOS denies access, an Open iOS Settings action is available. Notification scheduling errors are separate from storage failures.
- **Default reminder time:** 09:00 device-local time for new soil/observation reminders, with a native time picker and Save/Cancel. It prefills new explicit reminders and preset day choices. Existing tasks, chosen dates, and treatment-specific automatic review intervals are preserved. DST handling uses the device calendar.
- **Data & privacy:** clear up to five recent searches with confirmation; read how local data, selected photos, city lookup, approximate regional coordinates, and optional alerts work. Clearing searches leaves plants and preferences untouched.
- **About Bloom:** updated explanation of the curated care-plan POC, guidance source links, and actual bundle version. The sample-only start-fresh control remains available with its existing confirmation.

Preferences use the same atomic garden writes as plants. Older files decode without rewriting on read. New settings preserve the previous garden, with notification test doubles isolating scheduler/permission checks from the live app. No appearance themes, automatic watering schedules, generic treatment intervals, marketing alerts, accounts, or sync controls are added.

## Data and permissions

Plants, photos, setup choices, records, care plans, independent tasks, and reminder dates are stored locally using atomic writes and visible errors. Existing gardens are preserved. The optional sample garden starts with five plants and five labeled example activities; real gardens never receive sample plants.

Ordinary reminders and plan tasks are saved in-app independently of notification permission. Enable **Preferences → Task notifications** to request iOS alert access. New gardens start with alerts off; older gardens retain their existing alert intent. Ordinary scheduled checks then receive alerts, while plan tasks additionally require **Reschedule or set notification → Notify me**. Denying access keeps tasks saved, without repeated permission requests when adding reminders. Choose a preset, a custom date/time, or turn it off. Notification taps route to the relevant plant check or the exact independent plan task. Observation reminders retain their original observation instead of following the newest issue on that plant. Physical-device notification delivery/tap routing still needs verification. Automatic species identification, disease diagnosis, cloud sync, and community services are outside this MVP.

## Verification

See **Verification/Results.txt** for completed build and test results. Run the XCTest model tests and XCUITest journeys in Xcode with **⌘U**. UI tests use an isolated in-memory sample garden, preserving your saved garden and avoiding notification requests. Native screen captures are in **Previews**.

The standalone verification harness also runs the actual model without a Simulator:

```sh
xcrun swiftc Bloom/Models.swift Bloom/CarePlanModels.swift Bloom/CarePlanStore.swift Bloom/PlantSearchModels.swift Bloom/GrowingLocationModels.swift Bloom/AppPreferencesModels.swift Verification/StoreChecks.swift -o /tmp/BloomStoreChecks
/tmp/BloomStoreChecks
```

The focused remedy harness uses the same five model files with `Verification/RemedyChecks.swift`. Both harnesses create and remove only their own temporary fixtures.

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
- `CareGuidanceViews.swift`: saved-observation entry, focused assessment, explained recommendation, and explicit acceptance.
- `CarePlanViews.swift`: plan progress, baseline, rescheduling, stopping/resolution, and notes.
- `PlanTaskViews.swift`: action instructions, completion, comparison, Undo, and optional notifications.
- `CareFeed.swift`: native Tasks/Activity switch, grouped tasks, recent records, and connected record navigation.
- `AddPlantFlow.swift`: search → review/photo → room → status → plant detail.
- `PlantDiscovery.swift`: neutral search field, seasonal picks, recent searches, ownership badges, photo cards, care/light metadata.
- `PlantSearchModels.swift`: optional saved area/light preferences, hemisphere/season rules, explainable ranking, aliases and recent-query storage.
- `GrowingLocationModels.swift`: resolved city, coarse coordinates, climatology decoding, and plant-form metadata.
- `GrowingLocationService.swift`: city search, climate lookup, bounded/cancellable Core Location, and reverse geocoding.
- `PlantPreferenceArtwork.swift`: scalable code-drawn light and plant-form illustrations.
- `PlantSearchPersonalizationView.swift`: inline location search, compact light choices, visual multi-select plant forms, and draft Reset.
- `PlantSetupViews.swift`: room presets.
- `CareViews.swift`: soil checks, saved state, reminders, history, comparisons.
- `ObservationViews.swift`: plant-specific observations, optional context, support.

## Original Figma references

- [Lo-fi flow](https://www.figma.com/design/n3dPoS2OakACxSrkbu8cfW/Plant-care-app---Bloom?node-id=2469-8834)
- [Observation journey](https://www.figma.com/design/n3dPoS2OakACxSrkbu8cfW/Plant-care-app---Bloom?node-id=2400-15956)
- [User journey](https://www.figma.com/design/n3dPoS2OakACxSrkbu8cfW/Plant-care-app---Bloom?node-id=2176-11493)
- [Intentional care journey](https://www.figma.com/design/n3dPoS2OakACxSrkbu8cfW/Plant-care-app---Bloom?node-id=2281-13369)
- [Design system](https://www.figma.com/design/n3dPoS2OakACxSrkbu8cfW/Plant-care-app---Bloom?node-id=2340-14608)

Figma files were not modified. Their visual roles are implemented with reusable SwiftUI components.
