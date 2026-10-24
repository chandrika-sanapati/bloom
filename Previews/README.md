# Native iOS screens

**Current simplified flow:** [Area cards](49-native-choose-plant-area-cards.png) → [Change cards](50-native-choose-visible-change-cards.png) → optional photo/note → [What could help](56-native-straightforward-change-guidance.png) → [Back to the plant's next care task](57-native-added-care-returns-to-plant.png). Completing the [care task](58-native-concise-care-task.png) returns with [a confirmation and check-in date](59-native-action-saved-without-another-page.png); [progress choices](60-native-simple-progress-choices.png) use Better / Same / Worse. Bloom's existing colors, typography, photographs and card styles are retained. Earlier saved-receipt and mandatory plan-setup screens are historical and superseded.

Updated 2026-10-22. Captures from the running iPhone 17 app during XCUITest journeys, using an isolated sample garden. Test activities and added plants do not modify your saved garden.

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

## Compact cards and clear action states

Current collection cards keep only the name and location below the photo. Scheduled-check tags sit at the upper right, with no reserved empty row. Interface icons use shared square bounds and weight. Primary actions remain visible while disabled, using a neutral iOS system-gray fill and secondary-label text with no outline or icon. Continue stays visible in the change-selection step with a short hint.

- [Compact Home collection](64-native-compact-plant-collection.png)
- [Compact full collection](67-native-compact-all-plants.png)
- [Visible disabled Continue](65-native-visible-disabled-action.png)
- [Visible disabled plant-setup action](66-native-visible-disabled-plant-setup.png)
- [Change selection before a choice](69-native-visible-disabled-observation-action.png)
- [Disabled Continue at the largest text size](68-native-disabled-observation-accessibility-text.png)
- [Plant-detail photo filling its frame](70-native-edge-to-edge-plant-detail-photo.png)

## Compact progress and action records

The updated progress screen groups its context and shortens the four selection rows. Unselected choices are neutral; selected choices have a green check and tinted background. The completed action record combines metadata, shows **Action completed**, and groups related links. This status records a care action; resolving the plant issue remains a separate, explicit decision.

- [Compact progress choices before selection](72-native-compact-progress-choices.png)
- [Completed action record](73-native-compact-completed-action-record.png)

## Heading hierarchy and text-only actions

Page-copy titles, standalone section titles, card titles and supporting text use distinct system text styles. Native grouped section headings have increased prominence; custom section headings have VoiceOver heading semantics. Text-labelled command buttons omit decorative icons. The disabled style uses iOS system gray and secondary-label colors without the earlier custom green border; utility glyphs and informative visuals remain.

- [Home heading hierarchy and text-only Add plant](74-native-home-heading-hierarchy.png)
- [Neutral disabled action without an icon](75-native-neutral-text-only-disabled-action.png)
- [Observation heading and selection cards](76-native-observation-heading-hierarchy.png)
- [Care guidance headings and text-only action](77-native-guidance-heading-hierarchy-and-text-actions.png)

## Grouped plant identity

The plant-detail photo is followed by one shared name block. The plant name is the primary heading; the italic scientific name is directly beneath it. The navigation title keeps the plant context while scrolling.

- [Plant name and scientific name together](78-native-grouped-plant-name-and-scientific-name.png)

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

29–31 and 33 show the streamlined native Preferences menu, task notifications, default reminder-time picker, and cleared recent-search state. Plant discovery controls are available from Search plants → Personalize. Settings footer explanations have been removed; notification categories read Scheduled task and Care plan task. These captures use an isolated sample garden; the notification-permission result shown is simulated. No real GPS access or notification permission was requested by UI tests.

- [Preferences](29-native-app-preferences.png)
- [Task notifications](30-native-task-notification-preferences.png)
- [Default reminder time](31-native-default-reminder-time.png)
- [Earlier location-access menu · Historical](32-native-location-access-preferences.png)
- [Recent searches cleared](33-native-recent-searches-cleared.png)


## Leaf change to action and comparison

These isolated journeys show the new condition checks and source-backed starting actions. Three days is an editable comparison interval after a recorded action, not a recovery promise or another watering date. Severe signs use a prompt-help route. Existing saved gardens are not modified.

- [Condition checks](34-native-leaf-condition-checks.png)
- [Explained first action](35-native-explained-leaf-care-steps.png)
- [Record whether you watered or waited](36-native-explicit-watering-decision.png)
- [Action saved with the next check-in date](37-native-leaf-progress-check-scheduled.png)
- [Compare with the starting observation](38-native-leaf-before-and-after-comparison.png)
- [User-confirmed resolution](39-native-leaf-issue-resolved.png)
- [Soggy-mix alternative](40-native-wet-mix-alternative.png)
- [Prompt-help recommendation](41-native-leaf-urgent-support-route.png)


## Reaching next steps after saving

**Plant → Record a change → Leaves → Dropping leaves → Continue → Save change → Find next steps** opens the full-screen condition checks. Complete the remaining checks (Not sure is valid), then choose **See care steps**. Accepting the recommendation creates the action task and optional progress check. Close returns to the saved record, and Activity keeps the same entry.

- [Saved change and Find next steps](42-native-saved-change-next-steps.png)
- [Full-screen checks and remaining-answer hint](43-native-condition-checks-after-saving.png)


## Visual guidance · current flow

This replaces the mandatory leaf questionnaire shown in previews 34 and 43. **Find next steps** opens possible causes and illustrated first actions immediately. The cause cards explain possibilities; they are not a diagnosis picker. **Add care task** is enabled without checks. Optional observations refine the advice, with sources and longer instructions collapsed.

- [Immediate visual guidance](44-native-visual-next-steps-without-questions.png)
- [Optional observations](45-native-optional-visual-checks.png)
- [Refined first action](46-native-visual-care-action.png)
- [Illustrated care task](47-native-illustrated-first-care-task.png)

- [Largest accessibility text with available action](48-native-guidance-with-accessibility-text.png)


## Area cards and direct guidance · current entry

Tap an area card to see the changes for that part of the plant. Visible changes are single-selection cards, with a checkmark and border. Changing the area clears the previous change selection. Something else accepts a description. Standard text uses two columns; accessibility text uses one.

Save change opens the saved observation's guidance automatically; adding a care plan remains an explicit action. Close returns to the saved receipt, so Edit and Undo remain available.

- [Area cards](49-native-choose-plant-area-cards.png)
- [Visible-change cards](50-native-choose-visible-change-cards.png)
- [Saved notice and immediate suggested causes](51-native-save-opens-possible-causes.png)
- [Care plan accepted from this observation](52-native-accepted-care-plan-from-saved-change.png)
- [New pest observation's visual entry](53-native-pest-causes-after-saving.png)
- [Area cards with accessibility text](54-native-area-cards-accessibility-text.png)
- [Custom change with accessibility text](55-native-custom-change-card-accessibility-text.png)
