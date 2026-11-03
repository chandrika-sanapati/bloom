# Bloom interface guidelines

## Typography

Use the system font and four semantic roles. All roles scale with Dynamic Type.

| Role | Default size | Weight | Use |
| --- | --- | --- | --- |
| Title | 22 pt | Bold, system | One main content heading per screen |
| Section | 17 pt | Semibold | Section headings, card titles, action labels |
| Body | 17 pt | Regular | Questions, field values, instructions |
| Supporting | 13 pt | Regular | Dates, status metadata, short supporting text |

Native navigation and form controls retain iOS behavior. Avoid introducing additional text sizes. Use semibold for emphasis rather than a new size. Icons and artwork have their own scaled geometry.

## Color

Use the asset catalogue's semantic tokens. Teal identifies actions and selected choices. Blue identifies soil/water information. Yellow identifies observations or caution. Neutral colors identify unselected choices and metadata. Color must always be accompanied by a label or shape. Use the dark ink token on tinted surfaces, never the pale accent as body text. Preserve iOS adaptive colors in system controls and disabled actions.

## Actions

- Primary: shared `BloomPrimaryAction`, one full-width footer action per step, teal fill and white text.
- Secondary: native bordered buttons for alternate commands. Keep text labels explicit.
- Action row: shared `BloomActionRow` with a trailing chevron, minimum 44 pt target. Use it when the command opens another step.
- Utility: native navigation, menu, dismiss and photo controls. Utility icons use `BloomSymbol`'s square and semibold weight. Menu icons may clarify Edit and Remove.

Command buttons use text labels without decorative leading icons. Disabled primary actions retain a visible neutral fill and supporting selection guidance. Do not use a success symbol for Undo or cancellation.

## Layout and feedback

Use 16 pt card corners, 8 pt tag corners, 24 pt Home page margins and an 8 pt spacing rhythm (8/16/24/32 pt) for Home sections, cards, and grid gaps. Home and activity cards share the same 16 pt radius and 16 pt inner padding. Align card contents to a common leading edge; align dates and status tags consistently at the trailing edge, wrapping task metadata below titles at accessibility text sizes. Keep Home copy task-first and concise: status/title plus the plant name is enough; remove helper sentences that repeat the tab, action, or destination. Keep common and scientific names together. Avoid repeating the plant's name in the navigation bar. Keep activity links and See all consistent between Home and plant details.

Success names the object: “Snake Plant added” or “Snake Plant removed”. Completing an action records work, not plant recovery. Offer an optional progress check after the final action. Resolve an issue only through an explicit user choice.

## Accessibility

Maintain 44 pt interactive targets, readable text contrast, VoiceOver names and selected state, and Dynamic Type reflow. Home shows two complete cards initially; when more than two plants exist, let the next card peek into view to signal horizontal browsing, with See all preserved. Hide scroll indicators and avoid swipe-instruction text. At accessibility text sizes, two cards stack vertically and See all opens the full collection. Custom animations respect Reduce Motion. Body text and action labels must not be truncated to fit.

## Home and history

The Bloom leaf mark and name open Preferences. The top-right Add plant action is an outlined white circle with a teal plus when the collection is populated; on empty Home, the centered Add plant card is the only add action. Use real catalogue/plant-form/plant-area photos. Unknown custom plants invite a photo rather than showing an invented species. Keep search prompts inside their fields, dismiss controls icon-only with accessible names, and instructional copy only where it helps a care decision. Use standard SF Symbols that reinforce task meaning; do not add decorative icons. Keep Home status colors semantic and restrained: blue for soil, yellow for observations/review, neutral for empty/history states, teal only for primary actions and navigation. The plant page shows a dated, non-interactive Recent care overview beneath the common and scientific names: Last soil check and Last watered, each with its date or “Not recorded.” Keep it separate from reminder actions and omit it from the reminder editor. Basic Care actions and active Care plans occupy separate sections.


## Demo-aligned flows

Use the shared white selection group with 52 pt rows, a neutral unselected circle, and a teal selected check/background. Keep required choices separate from optional photo/note fields; show a concise selection hint beside a disabled fixed primary action. Room shortcuts are visible rather than hidden in a menu. Save belongs at the bottom of growing-space preferences; reset belongs with the choices.

Primary care and observation journeys use the full screen. Keep guidance summaries concise and avoid repeating possible causes or step descriptions; leave detailed instructions in a clearly labeled disclosure. Do not add an optional assessment questionnaire or a secondary help prompt to the first guidance screen: keep missing evidence unknown and recommend inspection rather than inferring treatment. Observation notes and an icon-led compact photo tile are optional and immediately visible. Saving a progress comparison shows a dedicated result with a next step; it never implies that completing treatment resolved the issue. Keep platform date/permission controls native. Use yellow for open/review care states, green for completed/resolved states, and neutral for stopped/skipped states. Collection cards carry identity; Care rows carry task tags.

Use the same outlined plus control in the populated Home header and full My plants toolbar. Empty Home uses one centered Add plant card, without a duplicate header plus. After plant selection, Add plant shows a compact identity summary and a collapsed Add details disclosure for optional photo, placement, room, and first impression. Keep the primary Add plant action available; skipped details remain unset. Record soil and the care decision on one screen with one Save action; saving returns to the previous screen with brief confirmation and Undo instead of a separate receipt page. On plant details, show entered information rather than empty “Not set” rows. For each active care plan, emphasize the saved observation and present one clear, readable next action; show its due date in a separate, non-interactive status row outside the action target. Show reminder dates in the same quiet status-row treatment, separate from Set/Edit reminder. Status-row labels use body-size semibold text; values remain body-size with ink emphasis. Keep Care plan details as a full-size secondary action row. Group past plans under Care plans with readable observation titles and clear status tags. Navigation rows throughout the app use Bloom's teal custom chevron consistently; full-card navigation and section-header actions such as See all remain arrow-free. Primary actions should name the action: Add plant, Save check, Review change, Save care, and Close record. Keep native navigation icons and standard date/settings controls.

On Home, name the section Activity and its tabs Upcoming and Past. Upcoming shows open tasks; Past shows saved records. Keep these labels distinct from the Care actions within an individual plant.

Do not repeat Upcoming as a heading inside the Upcoming tab. Keep Overdue and Today headings when they help distinguish task timing.

Always present Recent care on the plant page inside a quiet inset block with only two independent rows: Last soil check and Last watered. Give each row a small, subdued semantic symbol, a primary label, and a quieter date aligned to the right; separate the rows with a fine divider, without soil-condition tags or filler detail. Derive Last watered from actual watering history or the explicitly saved watering date; missing dates say Not recorded. Keep recorded actions in activity history. Show short dates, retain full timestamps for VoiceOver, and stack each row's contents at accessibility text sizes.

Plant identity is fixed after creation. Show the plant type as read-only information in the editor and plant details. Saving personal details may update photo, placement, room/location, initial condition, light, and drainage, while preserving the plant name, scientific species, reference image, existing care records, watering history, and current scheduling data.

## UX decision-making

The agent working on Bloom should act as a senior mobile UX/UI designer as well as an engineer. Evaluate suggestions from the customer's perspective: task flow, information hierarchy, discoverability, accessibility, native iOS conventions, privacy, and interaction cost. Do not implement feedback mechanically when it appears to add friction, duplicate information, overemphasize optional setup, or weaken an established pattern. Briefly explain the concern and recommend a better alternative before making a materially different change; ask when the intended tradeoff is unclear. Once a direction is agreed, implement it consistently and keep the primary customer task direct.
