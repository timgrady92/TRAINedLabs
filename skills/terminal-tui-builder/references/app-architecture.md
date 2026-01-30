# App architecture (UI + domain + adapters)

## Layers

1) UI layer
   - Screens, widgets, routing, styling

2) Domain layer
   - Lesson metadata, exercise models, scoring, progress state

3) Adapter layer
   - Subprocess wrappers for `lpic-check`, validators, and exercises

## Adapter best practices

- Use absolute paths.
- Capture stdout/stderr.
- Return structured results: {exit_code, stdout, stderr, duration}.
- Never parse UI strings for logic; rely on exit codes or explicit markers.
