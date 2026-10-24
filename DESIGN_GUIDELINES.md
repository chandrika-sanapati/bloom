# Bloom interface guidelines

## Typography

Use the system font and four semantic roles. All roles scale with Dynamic Type.

| Role | Default size | Weight | Use |
| --- | --- | --- | --- |
| Title | 22 pt | Bold, rounded | One main content heading per screen |
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

Maintain 44 pt interactive targets, readable text contrast, VoiceOver names and selected state, and Dynamic Type reflow. Horizontal collections show a partial next card and a scroll indicator. Custom animations respect Reduce Motion. Body text and action labels must not be truncated to fit.
