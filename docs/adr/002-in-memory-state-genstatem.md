# ADR-002: In-Memory Game State with GenStateMachine

## Status

accepted

## Context

Each game room manages mutable state (players, scores, timelines, current track, turn phase) that is modified
concurrently by 2-8 players in real time. The state has a well-defined lifecycle: lobby -> in progress (with nested turn
phases: waiting, ready, challenging, results) -> finished. Turn phases have timers (e.g., 8 seconds for challenging).

No persistent entities exist in the system - identities are ephemeral (ADR-006), leaderboards and history are out of MVP
scope. There is nothing that needs to survive a server restart.

Two sub-decisions: where state lives and how to model the lifecycle.

## Options

### Where state lives

- **PostgreSQL** - adds an external dependency for data that is ephemeral by design. +5-15ms roundtrip on every mutation
  during a timed 8-second phase. Requires running postgres in dev, CI, and production.

- **ETS table** - fast concurrent reads but no write serialization. Two players making assumptions simultaneously
  creates a race condition where order matters.

- **Process state (one process per room)** - state is an Elixir struct in process memory. Mailbox serializes concurrent
  mutations naturally. Process lifecycle = game session lifecycle. Zero external dependencies.

### How to model lifecycle

- **GenServer with conditional logic** - works for simple cases. But no guarantee that all state/event combinations are
  handled. Timers require manual scheduling, storing references, and cancellation. Adding a new phase means auditing
  every handler.

- **GenStateMachine (gen_statem)** - compound states are a first-class concept. Each state/event combination is an
  explicit clause - missing combinations are immediately visible. Built-in state timeouts auto-cancel on state change.
  Declarative actions instead of imperative timer management.

## Decision

Game state lives in-memory inside a GenStateMachine process, one process per room. No database.

Compound states `{game_status, turn_phase}` model the nested lifecycle. State transitions are explicit clauses. Built-in
state timeouts handle timed phases without manual timer management. Processes are started on demand via
DynamicSupervisor and terminate naturally when finished.

States:

- `{:waiting, :none}` - lobby
- `{:in_progress, :waiting}` - between turns
- `{:in_progress, :ready}` - track selected
- `{:in_progress, :challenging}` - timer running, players guessing
- `{:in_progress, :results}` - scores shown
- `{:finished, :none}` - game over, 3-minute cleanup timeout

## Consequences

- (+) Zero latency on state reads/writes
- (+) Mailbox serializes concurrent mutations - no race conditions
- (+) No database dependency - simpler dev, CI, and production setup (`ecto_repos: []`)
- (+) Compound states model nested lifecycle cleanly
- (+) `state_timeout` auto-cancels on transition - no manual timer management
- (+) Explicit state/event clauses make illegal transitions visible
- (-) Game state is lost if the BEAM node crashes mid-session
- (-) No replay or history feature without an additional persistence layer
- (-) gen_statem API has a steep learning curve
- (-) Testing requires simulating full state machine transitions

## Code References

- `lib/songy/core/game.ex` - Game struct definition
- `lib/songy/boundary/game_session.ex` - GenStateMachine implementation with all state callbacks
- `config/config.exs` - `ecto_repos: []`
