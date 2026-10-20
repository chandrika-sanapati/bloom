# Native iOS screens

Updated 2026-10-20. Captures from the running iPhone 17 app during XCUITest journeys, using an isolated sample garden. Test activities and added plants do not modify your saved garden.

Home combines a horizontal **My plants** row with **Care → Tasks / Activity**. The fixed header has a preferences gear; there is no bell destination or bottom tab bar. Plant cards open details, while See all opens the full searchable collection. The labelled Add plant action belongs directly below the plant cards; the floating Home plus has been removed.

- [Home and Care tasks](01-native-home.png)
- [Horizontal plant selection](11-native-horizontal-plants.png)
- [Care activity](02-native-care-activity.png)
- [A completed task in Activity](12-native-task-saved-to-activity.png)
- [Home without scheduled tasks](10-native-home-without-tasks.png)
- [Activity before the first record](13-native-empty-activity.png)
- [Search and choose a plant](06-native-discovery.png)
- [Choose a room](07-native-location.png)
- [Current status](08-native-current-status.png)
- [New plant detail](native-plant-detail-after-adding.png)
- [Check the soil](03-native-soil-check.png)
- [Record a decision](04-native-decision.png)
- [Saved record and next steps](05-native-saved-record.png)

## Observation to remedy

The new remedy captures use isolated sample plants and observations. They show an explained provisional recommendation, explicit acceptance, action completion, comparison, and user-confirmed resolution. They do not modify the saved garden.

- [Saved observation and next steps](14-native-saved-observation-next-steps.png)
- [Assessment](14-native-assessment.png)
- [Explained recommendation](15-native-explained-care-plan.png)
- [Accepted care plan](16-native-accepted-care-plan.png)
- [Action recorded](17-native-care-action-saved.png)
- [Progress comparison](18-native-compare-plan-progress.png)
- [Explicit resolution](19-native-explicitly-resolved-plan.png)
- [Inspection when evidence is uncertain](20-native-inspection-alternative.png)
- [Reassessed plan](21-native-reassessed-plan.png)

## Personalized plant search

A saved city or Locate me supplies seasonal context automatically. Compact text light choices and illustrated multi-select plant forms shape explained picks. Locate me sits at the right of the city field; Reset preferences stays available while scrolling. Recent searches stay local, ownership is visible, and unlisted plants can still be added by name. These are curated suggestions from the small indoor catalog, not live local trend data.

- [Growing-space preferences](22-native-growing-area-preferences.png)
- [Personalized seasonal picks](23-native-personalized-seasonal-picks.png)
- [Recent plant searches](24-native-recent-plant-searches.png)
- [Adding an unlisted plant](25-native-unlisted-plant-search.png)

- [Compact light choices and visual plant shapes](26-native-visual-plant-preferences.png)
- [Manual city search after location access fallback](27-native-location-access-fallback.png)

- [Reset light and plant types together](28-native-compact-preference-reset.png)

## App preferences

29–33 show the native grouped Preferences menu, task notification control, default local reminder-time picker, location-access status, and cleared recent-search state. Settings and Search share the growing-space profile. These captures use an isolated sample garden; the notification-permission result shown is simulated. No real GPS access or notification permission was requested by UI tests.

- [Preferences](29-native-app-preferences.png)
- [Task notifications](30-native-task-notification-preferences.png)
- [Default reminder time](31-native-default-reminder-time.png)
- [Location access](32-native-location-access-preferences.png)
- [Recent searches cleared](33-native-recent-searches-cleared.png)
