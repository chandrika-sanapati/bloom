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

Use 16 pt card corners, 8 pt tag corners, 20 pt page margins and a 4/8/12/16/24 pt spacing rhythm. Keep common and scientific names together. Avoid repeating the plant's name in the navigation bar. Keep activity links and See all consistent between Home and plant details.

Success names the object: “Snake Plant added” or “Snake Plant removed”. Completing an action records work, not plant recovery. Offer an optional progress check after the final action. Resolve an issue only through an explicit user choice.

## Accessibility

Maintain 44 pt interactive targets, readable text contrast, VoiceOver names and selected state, and Dynamic Type reflow. Home shows two complete cards initially, with horizontal browsing for the rest and See all preserved. Hide scroll indicators and avoid swipe-instruction text. At accessibility text sizes, two cards stack vertically and See all opens the full collection. Custom animations respect Reduce Motion. Body text and action labels must not be truncated to fit.

## Home and history

The Bloom leaf mark and name open Preferences. The top-right Add plant action is an outlined white circle with a teal plus; the solid teal brand mark remains visually distinct. Use real catalogue/plant-form/plant-area photos. Unknown custom plants invite a photo rather than showing an invented species. Keep search prompts inside their fields, dismiss controls icon-only with accessible names, and instructional copy only where it helps a care decision. The last soil check is dated, non-interactive plant status within the top plant card, beneath the common and scientific names. Keep it separate from reminder actions and omit it from the reminder editor. Basic Care actions and active Care plans occupy separate sections.


## Demo-aligned flows

Use the shared white selection group with 52 pt rows, a neutral unselected circle, and a teal selected check/background. Keep required choices separate from optional photo/note fields; show a concise selection hint beside a disabled fixed primary action. Room shortcuts are visible rather than hidden in a menu. Save belongs at the bottom of growing-space preferences; reset belongs with the choices.

Primary care and observation journeys use the full screen. Present numbered action instructions and optional notes directly. Saving a progress comparison shows a dedicated result with a next step; it never implies that completing treatment resolved the issue. Keep platform date/permission controls native. Use yellow for open/review care states, green for completed/resolved states, and neutral for stopped/skipped states. Collection cards carry identity; Care rows carry task tags.

Use the same outlined plus control in the Home header and full My plants toolbar. Primary action labels name the next step: Choose location, Choose condition, Record care decision, Review change, Save care, and Close record. Keep native navigation icons and standard date/settings controls.

On Home, name the section Activity and its tabs Upcoming and Past. Upcoming shows open tasks; Past shows saved records. Keep these labels distinct from the Care actions within an individual plant.

Do not repeat Upcoming as a heading inside the Upcoming tab. Keep Overdue and Today headings when they help distinguish task timing.
