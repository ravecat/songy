## Why

Songy already has rooms, music providers and a working timeline loop, but its timed, point-scoring challenge rules
differ from the publisher's Hitster Original rules. We need a traceable rule contract and an implementation backlog
before changing the state machine or accepting results as rule-correct.

## What Changes

- **BREAKING** Replace the current timed assumption contest with Original-style card placement, optional token-backed
  challenges, reveal, card ownership and a ten-card victory condition.
- Make setup, turn order, placement validation, same-year handling, token accounting and simultaneous challenge
  resolution explicit server rules.
- Define room configuration, disconnection and rematch behavior for a digital session, including permissions and
  client-visible errors.
- Guarantee playable track selection, safe reveal timing, provider failure handling and per-viewer snapshot visibility.
- Record round outcomes and gameplay events so result validation and playtests can audit each transition.
- Preserve the implemented Songy loop as a documented baseline, with relevant historical commit references in
  [the commit map](../../../docs/gameplay-commit-map.md).

This proposal assumes Hitster Original as the target rule set. Teams, Pro, Expert and Cooperative modes remain separate
follow-up scopes. Product decisions still needed are listed in the design and tasks; they must be resolved before
implementation of the affected behavior.

## Capabilities

### New Capabilities

- `gameplay-audit`: Record immutable round decisions and emit events needed to verify outcomes and diagnose failures.

### Modified Capabilities

- `room-lifecycle`: Configure and start a rule-based room, handle disconnects and run a rematch with the same
  participants.
- `timeline-turns`: Replace point-scoring assumptions with Original placement, token challenge, reveal and card-count
  victory rules.
- `music-providers`: Require a usable track and controlled playback or fallback without leaking unrevealed metadata.

## Impact

- Game core and FSM: `lib/songy/core/{game,turn}.ex`, `lib/songy/boundary/{game,game_session}.ex`, authorization and
  channel handlers.
- Contracts and UI: `priv/specs/asyncapi.yaml`, generated client schemas, game/room components and session stores.
- Provider adapters, playback UI and configuration; targeted core, FSM, channel, browser and multi-client tests.
- Rule source: [publisher instructions](https://hitstergame.com/en-nl/pages/how-to-play-original); local
  [reference and differences](../../../docs/hitster-original-reference.md).
