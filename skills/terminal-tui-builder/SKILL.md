---
name: terminal-tui-builder
description: Create or rebuild modern, feature-rich terminal UI (TUI) applications with full-screen layouts, transitions, and strong feedback. Use for LPIC-1 training front ends, command-line practice apps, or any request to design a visually pleasing offline terminal application, including stack selection (Textual/Bubble Tea/Ratatui) and integration with this repo's training scripts.
---

# Terminal TUI Builder

Build a high-quality terminal front end for LPIC-1 training and command practice. Prioritize a single-pane, app-like experience with clear navigation, transitions, and continuous feedback. Offline-first is mandatory.

## Quick start

1) Identify the primary user journey (learn -> practice -> check -> progress).
2) Choose the TUI stack (default to Textual unless Go/Rust is required).
3) Map repo data sources to views (lessons, exercises, validators, progress DB).
4) Build a single-pane layout with tabs/panels and an always-visible status bar.
5) Wire actions to existing scripts first, then enhance UX.

## Stack selection (short rule)

- Prefer **Python + Textual** for maximum UI richness, theming, layout, and transitions.
- Use **Go + Bubble Tea** when you need a static binary or the team is Go-first.
- Use **Rust + Ratatui** when you need performance and Rust toolchains are standard.

If unsure, choose Textual and implement a clean separation between UI and command execution so you can swap stacks later.

## Workflow

1) Inventory required tasks and data sources.
   - Lessons and exercises live under `core/training/`.
   - Validators and progress live under `core/` and `/opt/LPIC-1/data`.
   - See `references/repo-integration.md`.

2) Define the app shell.
   - Single-pane layout: left navigation, main content, right context panel, bottom status bar.
   - Keep the command practice console embedded instead of spawning new panes.
   - Use transitions for screen changes and inline status updates.

3) Build UI architecture with strict separation.
   - UI layer: views, widgets, routing, styling.
   - Domain layer: lesson/exercise metadata, progress state, validation logic.
   - Adapter layer: shelling out to existing scripts and parsing output.

4) Wire core features in this order.
   - Dashboard (progress + recommendations)
   - Lessons and guided practice
   - Command practice (hints + validation)
   - Exams and challenges

5) Harden for offline use.
   - No external calls.
   - Show clear dependency checks with actionable remediation.

## Reusable assets

If you need a starting point for Textual, copy:
`assets/textual-app-template/`

## When to load references

- For repo-specific paths and scripts: `references/repo-integration.md`
- For UI behavior and layout rules: `references/ux-guidelines.md`
- For Textual patterns and widget usage: `references/textual-notes.md`
- For app architecture and data flow: `references/app-architecture.md`
