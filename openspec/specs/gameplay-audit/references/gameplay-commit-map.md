# Gameplay commit map

This retrospective maps the current Songy implementation to delivery history before the Hitster Original rule-alignment
change. It was prepared from the 529 commits reachable from `72f5395` on 2026-09-30. A commit subject is evidence of
intent; the current code and tests determine whether behavior is still present. The full index below includes every
reachable commit whose subject starts with `feat` or `feature`; the table also names selected fixes and refactors that
materially changed behavior. Infrastructure-only and test-only commits are not treated as game features.

| Capability                                        | Delivery evidence                                                                                                                                        | Current state and remaining work                                                                                                             |
| ------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| Ephemeral rooms, identities, presence and sharing | `ed7ae88`, `406509a`, `2579fe5`, `2ca8433`, `1feca0c`, `7830e25`, `47d78b9`, `9fd88cd`, `9d07a76`, `e941ca8`, `a499fa4`, `0812625`                       | Rooms and snapshots exist. `/create` uses fixed defaults; active-room admission, reconnect and same-participant rematch need explicit rules. |
| Timeline and turn state                           | `1a252c2`, `186395d`, `265ac82`, `571da00`, `9b0be61`, `c903025`, `e5b19bb`, `e193648`, `1a70e9d`, `82d8fa0`, `66563ca`, `d8d16ca`, `f54e887`, `f4ef06c` | A server FSM and ordered slot check exist. Invalid submitted positions can be clamped; Original placement and reveal need a new turn record. |
| Songy challenge, scoring and finish               | `bd9dd67`, `c650715`, `dbe39ad`, `61fe0b6`, `2e45051`, `c95aaed`, `03b47f9`, `6e34858`, `5555d79`, `adc9b8e`, `f654d2b`                                  | A timed contest gives one selected valid assumption a point and card. This differs from Original token challenges and card-count victory.    |
| Gameplay and result UI                            | `55db716`, `6c8c074`, `9a2ea85`, `b63eb80`, `07e63e6`, `382c84f`, `f654d2b`, `aa04770`, `6d34148`, `8625b83`                                             | Lobby, timeline, challenge, reveal and finish views exist for Songy's current rules.                                                         |
| Spotify and provider abstraction                  | `cebee6b`, `f541382`, `f040f63`, `c921569`, `7a6b2f7`, `0cd752a`, `9804abe`, `29241e9`, `ef7dde5`                                                        | Spotify auth/playback and provider resolution exist. Fallback is primarily at session acquisition, not a failed turn.                        |
| Apple Music and iTunes                            | `8bf1975`, `94e7935`, `2cd41af`, `6d9d1c1`, `ba5a292`, `9fae212`, `8d11c8c`, `2dd37b0`                                                                   | Apple is the configured default. Preview and candidate availability need end-to-end verification before rule scoring.                        |
| Contracts and validation scaffolding              | `154d264`, `32ccd07`, `b786333`, `8f92e55`, `e0c313a`, `3defb8c`, `d6d6724`                                                                              | AsyncAPI, E2E, browser and Storybook coverage exist. Rule-derived golden cases and race/failure tests remain.                                |
| Replay entry                                      | `58eecfc`                                                                                                                                                | The replay button creates a fresh empty room, so a same-participant rematch is still open.                                                   |

See the current [room](../../room-lifecycle/spec.md), [turn](../../timeline-turns/spec.md) and
[provider](../../music-providers/spec.md) specifications, then the
[rule-alignment tasks](../../../changes/align-gameplay-with-hitster-original/tasks.md). No Git commits were amended or
reordered.

## Full feature-commit index

- `cebee6b` feat: add spotify authorization flow
- `e84e52b` feat: add core data structures
- `ed7ae88` feat: add game session logic
- `f58e199` feat: show game room page with basic user data
- `7b9dbd1` feat: show active user in room
- `406509a` feat: start game session
- `1feca0c` feature: show online users in room
- `7830e25` feat: preserve current user between session
- `e60baf8` feature: change game status to start
- `4ec9957` feat: add current device to spotify player
- `2176d7e` feat: set active music device
- `2579fe5` feat: add game session owner
- `f4c51a5` feat: show play button for active game
- `e898c3f` feat: enhance game session data with provider
- `1e92a73` feat: protect some provider specific routes
- `b1fc7cb` feat: store spotify device id in game session
- `3879052` feat: set owner device as active spotify device
- `eb7f4ab` feat: toggle playback
- `47d78b9` feat: auto terminate empty game session
- `fa47ac9` feat: update user list view
- `bbaa77d` feat: add track card component
- `1a252c2` feat: add turn structure
- `186395d` feat: add turn to game structure
- `f541382` feat: get random spotify track
- `265ac82` feat: add timelines to game
- `571da00` feat: add timeline validation
- `9b0be61` feat: create initial timeline on join user
- `07d38c0` feat: make draggable timeline
- `c903025` feat: add game turn logic
- `a52a0e2` feat: add track to game session
- `0fd6936` feat: add unknown track card
- `306b019` feat: play random track for active session
- `e5b19bb` feat: implement turn phases
- `97d28b2` feat: add highlight to personal participant tile
- `c59c523` feat: add turn wating modal
- `100143d` feat: show current player's turn data
- `55db716` feat: make turn ready screen
- `15d5550` feat: implement playing phase
- `8158f4f` feat: add turn ready phase transition
- `d65a5a4` feat: show ready buttom on unknow track card
- `e193648` feat: add transition to challenging phase
- `bd9dd67` feat: extend turn core with challenge functionality
- `e35073d` feat: get new random track after turn cycle
- `6c8c074` feat: show challenger screen on challenge phase
- `dbe39ad` feat: record active player assumption
- `55be3c4` feature: display assumption author on hidden track card
- `1a70e9d` feat: add transition to results phase
- `61fe0b6` feat: add scores to game structure
- `b65c6a8` feat: show score indicator for user
- `2e45051` feat: score participant results during result phase
- `6141698` feat: stop playback after full turn rotation
- `c95aaed` feat: extend winner's timeline during phase transition
- `03b47f9` feat: add winning score options to game
- `6e34858` feat: change game status on winnging condition
- `d0b87a6` feat: disable dnd for non-challengers
- `ab24803` feat: restrict dragging to user's own assumptions
- `58eecfc` feat: add game replay functionality
- `27d9804` feat: restrict ready button to active player only
- `f040f63` feat: add credential registry
- `4966f81` feat: add update provider channel event
- `c921569` feat: add provider behavior
- `f795b55` feat: init spotify provider structure
- `a970c32` feat: add player protocol
- `7a6b2f7` feat: implement player for spotify provider
- `0cd752a` feat: implement provider protocol for spotify
- `8bf1975` feat: add apple provider structure
- `9b617df` feat: add search method to apple music provider
- `94e7935` feat: add search random track to apple music provider
- `d85c153` feat: create apple track structure
- `d52dba5` feat: implement player protocol for apple music provider
- `c6ca147` feat: add apple music component provider
- `724822b` feat: improve real-time game state synchronization reliability
- `9fd88cd` feat: implement game session supervisor
- `ee6e572` feat: enable playback control for active/owner user
- `f237a4d` feat: update player block
- `7c51856` feat: add channel wrapper
- `fea7889` feat: implement derived permissions
- `5f2325c` feat: implement PaaC for backend authorization
- `c890044` feat: implement PaaC for frontend authorization
- `5555d79` feat: add challenge timer
- `7d1dddf` feat: make scrollable timeline
- `809abfe` feat: add policy validation to game actions
- `87bc343` feat: hide active track for active player during challenging phase
- `2cd41af` feat: enable apple provider
- `4b8a292` feat: add info block to header
- `b5996ae` feat: add provider description to home page
- `6d9d1c1` feat: add itunes provider
- `ba5a292` feat: add player for url-based content provider
- `7cf8f0e` feat: add wrapper for common wrapper
- `4af6a1c` feat: increase random track combination for itunes
- `c2af46b` feat: auto scroll active timeline for challenger
- `1bc9874` feat: disable forward button without assumption
- `9a2ea85` feat: implement timeline with available slots
- `b63eb80` feat: show song vinyl sleeve during results phase
- `07e63e6` feat: add challengers' avatars to results display
- `e1365e8` feat: introduce CSS variables system for design tokens
- `63f765b` feat: enhance results with challengers info
- `382c84f` feat: show winner in result phase
- `9d07a76` feat: add QR code generation for room sharing
- `e725c90` feat: redesign player controls to 3-slot grid layout
- `b696ca4` feat: add timeline scroll button
- `b2c2f98` feat: make only time slots scrollable
- `154d264` feat(asyncapi): add asyncapi spec and docs endpoints
- `32ccd07` feat: unify contract artifacts
- `f4418f7` feat(storybook): serve static build via phoenix
- `f654d2b` feat(room): add finished game page
- `aa04770` feat(room): refresh lobby status UI
- `6d34148` feat(room): show current player in header
- `8625b83` feat: refresh challenging phase timer
- `9fae212` feat(provider): switch default provider to Apple Music
- `bf98480` feat(provider): add dedicated cover track search
- `8d11c8c` feat(apple): weight random search offsets by year
- `2dd37b0` feat(apple): add filter genre list for random search
