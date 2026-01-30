# Textual notes (Python)

Use this when building the default stack.

## Core concepts

- App: main entry point.
- Screen: full-page view with lifecycle methods.
- Container layout: Horizontal, Vertical, Grid.
- Reactive state: triggers UI updates automatically.
- CSS: style widgets, colors, spacing, borders, transitions.

## Recommended structure

- `app.py` defines App and routing.
- `views/` or `screens/` hold major screens.
- `widgets/` contains reusable UI pieces.
- `services/` contains subprocess execution and parsing.

## Interaction patterns

- Use a fixed status bar + event log.
- Keep validation output in a scrollable text area.
- Use a command input widget with history.
