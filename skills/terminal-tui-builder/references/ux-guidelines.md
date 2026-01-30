# UX guidelines for training TUIs

## Layout

- Single pane of glass: navigation + main content + context panel + status bar.
- Keep primary actions in one view; use modals only for confirmations.
- Always show current mode (Learn, Practice, Test, Exam) in the status bar.

## Navigation

- Keyboard-first. Provide visible key hints (e.g., F1 Help, F2 Search).
- Use consistent shortcuts across screens.
- Avoid deep navigation stacks; prefer tabs or segmented views.

## Feedback and transitions

- Animate between major views (fade/slide) and show loading spinners for tasks >300ms.
- Emit immediate success/fail signals on checks (color + icon + short text).
- Keep a running activity log in a collapsible panel.

## Training UX

- Show the task, the expected command shape, and a live scratch area.
- Provide tiered hints with a cost meter (affects score).
- Offer a rewind/restore action for labs.

## Accessibility

- Support low-color terminals; avoid relying only on color.
- Provide an ASCII-only mode where symbols are text-based.
- Respect terminal resize and reflow content.
