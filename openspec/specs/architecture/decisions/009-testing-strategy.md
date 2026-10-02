# ADR-009: Testing Strategy

## Status

accepted

## Context

The application spans Elixir backend (GenStateMachine, Channels, Controllers) and Svelte frontend. Need a testing
strategy that covers both without over-investing in any single layer. No database exists (ADR-002), so there is no Ecto
sandbox to manage.

## Options

- **Backend-only testing (ExUnit)** - fast and deterministic for domain logic and FSM. But leaves frontend untested -
  drag-and-drop timeline, channel wrapper, and audio playback are complex client-side behaviors.

- **E2E-only testing (Playwright)** - tests the full stack including real browser behavior. But slow, flaky, and
  expensive to maintain. Poor feedback loop for iterating on domain logic.

- **Multi-layer testing** - unit tests for domain logic, integration tests for FSM/channels/controllers, frontend tests
  for component behavior, E2E for critical flows. Each layer targets what it tests best.

## Decision

Multi-layer testing approach:

1. **Unit tests (ExUnit)** - core domain logic (Game, Turn, Track, User, Player structs), provider implementations,
   policy/authorization rules
2. **Integration tests (ExUnit)** - channel events, controller responses, FSM state transitions, auth flows
3. **Frontend tests (Vitest and Storybook)** - non-DOM unit tests plus production component scenarios with interaction
   assertions in Storybook `play` functions and visual comparisons after play
4. **E2E tests (Playwright)** - full browser flows (excluded from watch mode)

Property-based testing via `stream_data` for domain invariants.

## Consequences

- (+) Core logic tested in isolation - fast, deterministic
- (+) FSM transitions tested via boundary tests - catches illegal state changes
- (+) Frontend tests via Vitest - fast feedback on component behavior
- (+) Storybook and automated tests share scenarios, decorators, themes, and deterministic connected-dependency mocks
- (+) Screenshot execution follows Next Station Paris with sequential story files, reduced motion, and HTML failure
  reports
- (-) Screenshot comparisons allow up to 30 mismatched pixels; smaller differences can pass
- (-) Visual references require review in the pinned Linux Chromium and DejaVu fallback font environment
- (+) E2E validates full stack but runs separately from dev loop
- (-) No database to mock/sandbox (no Ecto sandbox) - simplifies setup but limits persistence testing
- (-) Channel tests require simulating full socket lifecycle
- (-) Property-based tests add maintenance overhead

## Test Commands

| Command                    | Scope                      |
| -------------------------- | -------------------------- |
| `just mix test`            | All Elixir tests           |
| `just mix test.only`       | Tests tagged `@tag :only`  |
| `just assets test`         | Unit and Storybook tests   |
| `just assets check`        | Svelte check               |
| `just assets typecheck`    | TypeScript check           |
| `just assets e2e`          | Playwright E2E             |
| `just assets test --watch` | Watch frontend tests       |
| `just assets test:visual`  | Storybook play and visuals |
| `just assets test:browser` | Legacy component tests     |

## Code References

- `test/songy/core/` - Unit tests for domain structs
- `test/songy/boundary/` - FSM and provider integration tests
- `test/songy_web/channels/` - Channel event tests
- `test/songy_web/controllers/` - Controller tests
- `assets/stories/` - Storybook scenarios and `play` assertions
- `assets/.storybook/vitest.setup.ts` - shared story setup and screenshot capture
- `assets/__screenshots__/` - reviewed visual references
- `assets/tests/` - unit tests and legacy component tests
- `assets/e2e/` - Playwright E2E tests
