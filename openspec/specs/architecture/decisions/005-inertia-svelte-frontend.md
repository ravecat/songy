# ADR-005: Inertia.js + Svelte 5 for Frontend

## Status

accepted

## Context

The application has two pages (home, room) but requires rich client-side interactivity: real-time game state updates,
drag-and-drop timeline, Spotify Web Playback SDK (JavaScript), animations. Server-rendered templates without a JS
framework are insufficient. A full SPA is excessive for two pages.

## Options

- **Phoenix LiveView** - server-rendered with minimal JS. But core UI requirements (Spotify Playback SDK, drag-and-drop
  timeline, audio visualization) are inherently client-side. LiveView hooks for these become a workaround: server
  rendering that still requires writing JS, with added round-trip latency on every interaction.

- **Pure SPA (React/Vue/Svelte) + REST API** - full client-side freedom. But for two pages this requires building and
  maintaining a client-side router, REST API layer, token management, and CORS configuration. Boilerplate exceeds
  business logic.

- **Inertia.js + Svelte 5** - server controllers render props, Svelte components render UI. No client-side router, no
  REST API, no token management. Server-driven page transitions with SPA user experience. Svelte 5 over React: for two
  pages, ecosystem size is irrelevant. Fine-grained reactivity with less boilerplate and smaller bundle.

## Decision

Inertia.js bridging Phoenix controllers to Svelte 5 page components. Strict separation of data delivery
responsibilities:

- **Inertia** handles page routing and static/initial props (which page to render, room existence, user permissions).
  Request/response model.
- **Phoenix Channel** handles all live game state (players, scores, turns, timers). Push model.

There is no overlap - Inertia does not deliver game state, Channel does not handle navigation. This avoids dual
source-of-truth problems and race conditions between page load and socket connection.

## Consequences

- (+) No client-side router, no REST API - minimal boilerplate for two pages
- (+) Server-driven page transitions with SPA feel
- (+) Svelte 5 runes for fine-grained reactivity with less code
- (+) Clear data delivery boundary: Inertia = navigation, Channel = game state
- (-) Less common stack - fewer community resources and examples
- (-) Two data delivery mechanisms to understand (Inertia + Channel), even though responsibilities don't overlap
- (-) Inertia ecosystem is smaller than pure SPA tooling

## Code References

- `config/config.exs` - Inertia configuration (`camelize_props: true`, `ssr: false`)
- `lib/songy_web/controllers/page_controller.ex` - `Inertia.render/3` calls
- `assets/js/pages/` - Svelte page components
- `assets/js/app.ts` - Inertia app initialization
