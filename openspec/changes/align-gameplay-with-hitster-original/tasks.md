## 1. Freeze the rule contract

- [ ] 1.1 Confirm Original mode as the target and decide whether the existing timed Songy contest remains a separate
      mode; update the PRD, proposal and acceptance matrix together.
- [ ] 1.2 Resolve seed-card and token-purchased-card counting, reveal timing, active-player disconnect and
      challenge-order policies against the
      [publisher rules](../../specs/gameplay-audit/references/hitster-original-reference.md); record each decision and a
      test case in the specs.
- [ ] 1.3 Define canonical release-year and title/artist answer policies, including remasters, aliases and unavailable
      metadata; add positive and negative fixtures.
- [ ] 1.4 Confirm rights and naming for independent digital playback before a public release; keep the publisher source
      URL and review date current.

## 2. Establish the authoritative game model

- [ ] 2.1 Replace point score and position-to-user assumptions with a turn identifier, active placement, ordered
      challenges, token balances and immutable result in `Songy.Core`; verify serialization and core tests.
- [ ] 2.2 Implement server slot validation, including equal-year neighbors and out-of-range rejection, with table-driven
      core tests.
- [ ] 2.3 Update the GenStateMachine to open placement, accept challenges and commit reveal exactly once; test valid and
      forbidden transitions.
- [ ] 2.4 Resolve one card recipient or discard atomically, including active-player priority and the first valid
      challenge; test competing and same-year cases.
- [ ] 2.5 End the game on the tenth qualifying card without starting another turn; test correct placement, challenge and
      token-exchange wins.

## 3. Implement token actions

- [ ] 3.1 Add an explicit token-mode setting with initial balance two, cap five and a token-free path; verify both room
      modes.
- [ ] 3.2 Implement one-token skip, one-token challenge and three-token direct-card exchange with authorization, balance
      and retry tests.
- [ ] 3.3 Award a token for a correct active-player title-and-artist answer under the agreed metadata policy, including
      incorrect placement and balance-cap cases.

## 4. Update room lifecycle and transport

- [ ] 4.1 Add validated room settings and seed-card assignment to the create/start path; test two-player, full-room and
      provider-failure cases.
- [ ] 4.2 Reject new player identities after start while allowing reconnect without duplicate cards or actions; test
      channel and presence races.
- [ ] 4.3 Implement the agreed active-player disconnect path and finished-room cleanup; test each phase and an empty
      room.
- [ ] 4.4 Define placement, challenge, token and reveal channel events in `priv/specs/asyncapi.yaml`, regenerate client
      contracts and return structured stale/invalid/unauthorized errors; test wire replies.
- [ ] 4.5 Project snapshots per viewer so unrevealed answers and private actions do not appear in wire payloads; inspect
      join replies and broadcasts with channel tests.

## 5. Make music reliably playable

- [ ] 5.1 Filter candidates without a canonical year or usable playback source and avoid repeat tracks within a room;
      test provider adapters and bounded search.
- [ ] 5.2 Make Apple Music and iTunes preview playback succeed or report failure from the actual client player; verify
      start, pause and unavailable-media behavior.
- [ ] 5.3 Retry or switch to an available provider after acquisition or playback failure before placement opens; test
      exhausted fallbacks and no-score failure.
- [ ] 5.4 Verify provider terms and regional behavior for the chosen playback path in a staged multiplayer session.

## 6. Complete the player experience

- [ ] 6.1 Replace point-score and timed-assumption UI with concealed active placement, token-backed challenges, reveal
      and card-count progress; run focused browser component tests.
- [ ] 6.2 Show token balances, accepted challenge order, same-year resolution and actionable server errors without
      exposing answers before reveal; validate two-client views.
- [ ] 6.3 Implement a rematch lobby with prior participants and settings but fresh seeds, tokens and outcomes; test
      finish-to-rematch flow.

## 7. Prove results and release readiness

- [ ] 7.1 Retain an immutable result record in each room process until it ends and emit room, turn, action, reveal,
      finish, rematch and fallback events without secret data; test idempotent reveal and event payloads.
- [ ] 7.2 Build a publisher-rule case table covering placement boundaries, equal years, wrong active placement, multiple
      challenges, token spending and victory; run focused core and FSM tests.
- [ ] 7.3 Run channel, browser and multi-client end-to-end checks for reconnect, stale requests, provider failure and
      simultaneous challenges; reconcile any failing scenarios with the specs.
- [ ] 7.4 Update the PRD, design doc, AsyncAPI artifacts, runbook and OpenSpec task statuses to the verified delivered
      state; validate OpenSpec, formatting and the affected native test targets before completion.
