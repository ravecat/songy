# Architecture Decision Records

## Status Legend

- **proposed** - under discussion
- **accepted** - active and enforced
- **deprecated** - superseded by a later ADR
- **superseded** - replaced (link to replacement)

## Decisions

| #                                                 | Decision                                     | Status   |
| ------------------------------------------------- | -------------------------------------------- | -------- |
| [000](000-template.md)                            | ADR template                                 | -        |
| [001](001-elixir-phoenix-runtime.md)              | Elixir/Phoenix as runtime platform           | accepted |
| [002](002-in-memory-state-genstatem.md)           | In-memory game state with GenStateMachine    | accepted |
| [003](003-phoenix-channels-realtime.md)           | Phoenix Channels for real-time communication | accepted |
| [004](004-provider-abstraction.md)                | Pluggable music provider abstraction         | accepted |
| [005](005-inertia-svelte-frontend.md)             | Inertia.js + Svelte 5 for frontend           | accepted |
| [006](006-ephemeral-identities.md)                | Ephemeral identities                         | accepted |
| [007](007-token-storage-ets.md)                   | Token storage in ETS                         | accepted |
| [008](008-scaling-single-node-sticky-sessions.md) | Single-node scaling strategy                 | accepted |
| [009](009-testing-strategy.md)                    | Testing strategy                             | accepted |

## Adding a New ADR

1. Copy [000-template.md](000-template.md)
2. Number sequentially (next: `010`)
3. Fill in all sections (Context, Options, Decision, Consequences)
4. Add entry to this table
5. Link from relevant docs
