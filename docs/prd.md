# PRD: Songy MVP Core Gameplay

## Metadata

- Title: Songy MVP Core Gameplay
- Owner: Max
- Contributors: Product, Engineering
- Status: solution-review
- Date: 2026-02-16
- Product brief: [product-brief.md](product-brief.md)
- Design doc: [design-doc.md](design-doc.md)
- ADR links: [adr/README.md](adr/README.md)

## Problem recap

Songy targets groups of friends who want fast, music-driven social play but avoid existing options due to setup friction
and fixed catalogs. The MVP must prove that a room-link multiplayer flow plus timeline placement mechanics can create
repeat play within the same session.

- Problem: setup-heavy and low-replay alternatives block spontaneous play
- Target user: party groups of 3-10 players with mixed music expertise
- Why now: provider APIs support track discovery plus short playback previews

## Goals and success metrics

- Business outcome: validate product-market signal for social replay behavior
- User outcome: create or join a room and complete a full match without account setup
- Leading metric: p50 time from room-link open to first active turn <= 45 seconds
- Lagging metric: >= 40% of completed matches trigger rematch in same session
- Failure condition: two consecutive cohorts with rematch rate < 20% or setup p50 > 90 seconds

## Non-goals

- NG-1: Persistent accounts, profiles, or long-term identity
- NG-2: Match history, progression, or achievements
- NG-3: Public matchmaking and ranking
- NG-4: In-app chat or voice channels
- NG-5: Native mobile applications
- NG-6: Title-recognition quiz mechanics

## User flows

### Flow 1: Create and join game

- Trigger: host wants to start a new game room
- Steps:
  1. Host opens `/create` and sets game configuration
  2. Server creates game room and redirects to `/:room_id`
  3. Host shares room link
  4. Participants open link and receive ephemeral identity
  5. Host starts game from lobby
- Outcome: all connected participants are in `waiting` state ready to start
- Error states: invalid room link, room full, room already in-progress

### Flow 2: Run gameplay turn

- Trigger: game is in progress and turn is advanced
- Steps:
  1. Server selects random track from active provider
  2. Players hear the same preview segment
  3. Active player places track on timeline
  4. Challenge phase starts and other players submit placement
  5. Timer expires or all assumptions received
  6. Correct year and scoring are revealed
  7. Next turn starts or winner is announced
- Outcome: score and timeline state mutate deterministically
- Error states: provider lookup failure, active player disconnect, timeout with no assumptions

### Flow 3: Connect Spotify provider

- Trigger: player wants Spotify playback path
- Steps:
  1. Player starts OAuth from game UI
  2. Spotify returns authorization code
  3. Server exchanges code for access and refresh tokens
  4. Token pair is stored server-side in ETS
  5. Player resumes room with provider enabled
- Outcome: playback can use Spotify SDK path
- Error states: denied consent, code exchange failure, refresh token failure

## Functional requirements

| ID    | Requirement                                                             | Flow | Priority | AC ID | Acceptance criteria                                                      |
| ----- | ----------------------------------------------------------------------- | ---- | -------- | ----- | ------------------------------------------------------------------------ |
| FR-1  | Host can create a game room with configurable settings                  | 1    | must     | AC-1  | Room is created with unique ID and host is redirected to lobby           |
| FR-2  | Participants join via shared room link with ephemeral identity          | 1    | must     | AC-2  | Opening room link generates UUID, display name, avatar, and joins lobby  |
| FR-3  | Only host can start the game                                            | 1    | must     | AC-3  | Non-host start attempts are rejected and logged                          |
| FR-4  | Duplicate join from same session is rejected                            | 1    | must     | AC-4  | Existing participant ID cannot join room twice                           |
| FR-5  | Server selects random track from configured provider                    | 2    | must     | AC-5  | Track payload includes title, artist, year, artwork, provider identifier |
| FR-6  | All participants receive synchronized turn state and timer              | 2    | must     | AC-6  | Channel broadcasts authoritative `state` and `timer` events              |
| FR-7  | Active player can place track on their timeline                         | 2    | must     | AC-7  | Placement must satisfy chronological ordering constraints                |
| FR-8  | Non-active players can submit one challenge placement during timer      | 2    | must     | AC-8  | Challenge phase ends at timeout or when all participants submitted       |
| FR-9  | Participant can update placement before timer ends                      | 2    | should   | AC-9  | Latest placement replaces previous submission                            |
| FR-10 | Correct placement scores +1, incorrect scores 0                         | 2    | must     | AC-10 | Score update follows deterministic rule on reveal                        |
| FR-11 | Reveal inserts track into winner timeline at correct position           | 2    | must     | AC-11 | Timeline remains chronologically sorted after insertion                  |
| FR-12 | First player to max score wins and ends game                            | 2    | must     | AC-12 | Game transitions to finished state with leaderboard                      |
| FR-13 | Tie-break prefers active player when multiple hit max score             | 2    | should   | AC-13 | Winner resolution rule applies consistently                              |
| FR-14 | Disconnected active player is skipped                                   | 2    | must     | AC-14 | Queue cursor advances to next connected participant                      |
| FR-15 | Players can connect Spotify provider through OAuth                      | 3    | should   | AC-15 | OAuth success enables provider-specific playback path                    |
| FR-16 | iTunes works as default provider without extra setup                    | 2    | must     | AC-16 | Room remains playable when Spotify is absent or disconnected             |
| FR-17 | Room config supports max score, timeout, genre filter, max participants | 1    | must     | AC-17 | Config values persist in game session state                              |
| FR-18 | Results screen supports rematch with same participants and config       | 2    | should   | AC-18 | New room or restarted session is available from results view             |

## Non-functional requirements

| ID    | Category      | Requirement                            | Threshold                                                |
| ----- | ------------- | -------------------------------------- | -------------------------------------------------------- |
| NFR-1 | performance   | In-memory game state mutation latency  | p95 < 1 ms per operation in isolated room                |
| NFR-2 | performance   | Room-wide event propagation            | p95 < 50 ms channel broadcast latency                    |
| NFR-3 | reliability   | Room fault isolation                   | Crash in one room must not mutate or block other rooms   |
| NFR-4 | security      | Provider tokens stay server-side       | No token in browser storage, cookies, or URL             |
| NFR-5 | authorization | Every mutation is role and state gated | 100% mutation actions pass policy check path             |
| NFR-6 | usability     | Onboarding time to gameplay            | p50 link open to first turn <= 45 seconds                |
| NFR-7 | availability  | Provider fallback behavior             | Automatic fallback to iTunes within one turn cycle       |
| NFR-8 | observability | Critical loop instrumentation          | Core gameplay events emitted for 100% of completed turns |

## Key data entities

| Entity          | Key attributes                                                                             | Related FR         | Notes                                  |
| --------------- | ------------------------------------------------------------------------------------------ | ------------------ | -------------------------------------- |
| GameSession     | id, owner_id, status, phase, queue, cursor, participants, timelines, scores, configuration | FR-1, FR-12, FR-17 | Authoritative aggregate per room       |
| Participant     | id, display_name, avatar, connected                                                        | FR-2, FR-14        | Ephemeral identity with presence state |
| Round           | track, assumptions, winner_id, started_at, ended_at                                        | FR-5, FR-8, FR-10  | Mutable only inside active turn        |
| TrackCandidate  | provider, external_id, title, artist, release_year, preview_url                            | FR-5, FR-16        | Normalized provider payload            |
| ProviderSession | user_id, provider, access_token, refresh_token, expires_at                                 | FR-15              | Stored server-side in ETS              |

## Edge cases

| ID   | Scenario                                         | Expected behavior                                           | Related FR   |
| ---- | ------------------------------------------------ | ----------------------------------------------------------- | ------------ |
| EC-1 | Room has transient disconnect bursts             | Presence updates participant flags without terminating room | FR-14        |
| EC-2 | Provider returns no tracks for configured filter | Retry with relaxed filter, then fallback to iTunes          | FR-5, FR-16  |
| EC-3 | Participant submits invalid placement index      | Server rejects mutation and returns error state             | FR-7, FR-9   |
| EC-4 | Challenge timer expires without submissions      | Turn resolves with zero score delta and advances            | FR-8, FR-10  |
| EC-5 | Spotify token expires mid-game                   | Server refreshes token or falls back to iTunes              | FR-15, FR-16 |
| EC-6 | Multiple players hit max score same reveal       | Active player wins by tie-break rule                        | FR-13        |

## Analytics and instrumentation

| Event                    | Trigger                        | Payload                                                | Related FR       |
| ------------------------ | ------------------------------ | ------------------------------------------------------ | ---------------- |
| `room_created`           | Host submits create-room form  | room_id, config, timestamp                             | FR-1, FR-17      |
| `room_joined`            | Participant enters room        | room_id, participant_id, join_latency_ms               | FR-2             |
| `game_started`           | Host starts game               | room_id, participant_count, config                     | FR-3             |
| `turn_started`           | State transition to `ready`    | room_id, round_index, provider                         | FR-5, FR-6       |
| `assumption_submitted`   | Participant placement accepted | room_id, participant_id, phase, position               | FR-7, FR-8, FR-9 |
| `turn_resolved`          | Reveal step completed          | room_id, winner_id, score_delta, challenge_duration_ms | FR-10, FR-11     |
| `game_finished`          | Winner detected                | room_id, winner_id, rounds_played, duration_ms         | FR-12, FR-13     |
| `rematch_started`        | Rematch action confirmed       | source_room_id, new_room_id, participant_count         | FR-18            |
| `provider_fallback_used` | Primary provider path fails    | room_id, failed_provider, fallback_provider, reason    | FR-16            |

## Dependencies

| Dependency                | Type (team / service / data / external) | Owner   | Status                        |
| ------------------------- | --------------------------------------- | ------- | ----------------------------- |
| Spotify Web API and OAuth | external                                | Spotify | active, quota constrained     |
| Spotify Web Playback SDK  | external                                | Spotify | active, browser-dependent     |
| iTunes Search API         | external                                | Apple   | active, no auth               |
| Apple Music API token     | external                                | Apple   | optional for expanded catalog |

## Rollout and support

- Rollout strategy (feature flag, % rollout, regional):
  - Start with internal alpha rooms only
  - Enable rematch and Spotify path behind server-side flags for controlled cohort rollout
  - Expand to open room creation after stability gate
- Rollback plan:
  - Disable gameplay creation flag and keep landing page available
  - Force provider path to iTunes-only mode if OAuth issues spike
  - Keep in-flight rooms until completion, block new room creation if critical
- Support owner:
  - Max (engineering owner during MVP)
- Known operational impact:
  - Real-time rooms increase concurrent process count rapidly during peaks
  - Provider API incidents directly affect turn continuity and perceived reliability

## Open questions

| Question                                                               | Owner | Next step                             | Deadline   | Status |
| ---------------------------------------------------------------------- | ----- | ------------------------------------- | ---------- | ------ |
| Should late joiners become spectators or active participants mid-game? | Max   | Decide after alpha telemetry review   | 2026-03-15 | open   |
| What timeout default balances pace and fairness across skill levels?   | Max   | Compare 6s, 8s, 10s in playtests      | 2026-03-10 | open   |
| Which minimum instrumentation dashboard is required before open beta?  | Max   | Define dashboard and alert thresholds | 2026-03-20 | open   |
