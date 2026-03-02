# Product Brief: Songy

## Metadata

- Author: Max
- Date: 2026-02-16
- Status: accepted
- Stakeholders: Product, Engineering, QA

## One-liner

Real-time multiplayer music timeline game for groups of friends: hear a track, guess its release year, place it in
chronological order.

## Insight or trigger

- Signal: party groups repeatedly drop board or trivia sessions due to setup friction, but still want music-based social
  play
- Source: founder observation from repeated game nights and competitor analysis of timeline board games
- Confidence: medium

## Problem

- Who has the problem: groups of 3-10 friends in party or remote hangout contexts
- What is the pain: current music quizzes require physical setup, fixed track catalogs, or local-only play
- Current workaround and its cost: board games plus QR cards, or generic trivia apps; both reduce replay value and add
  coordination overhead
- Root cause hypothesis: no digital-first product combines real-time group play with user-relevant music catalog
- Why now: streaming providers expose searchable catalogs and preview playback APIs suitable for fast multiplayer loops

## Target users and key scenarios

### Persona 1 - Party group host

- Goal: start game in under one minute and keep the room engaged
- Success signal: all invited players enter lobby without onboarding friction

### Persona 2 - Music enthusiast

- Goal: demonstrate era knowledge and drive social competition
- Success signal: plays multiple rounds and asks for rematch

### Persona 3 - Casual joiner

- Goal: understand mechanic instantly and participate without account creation
- Success signal: submits assumptions in first turn after joining

### Key scenarios

1. Start a game night via shareable room link
2. Run multiple quick rounds with stable real-time synchronization
3. Trigger rematch immediately from final results

## Goals and outcomes

- Business outcome: validate MVP retention signal for party-game sessions
- User outcome: start and complete a multiplayer timeline match with near-zero setup
- Leading metric: p50 time from room-link open to first active turn <= 45 seconds
- Lagging metric: >= 40% of completed matches start a rematch in the same session
- Failure condition: rematch rate < 20% for two consecutive validation cohorts, or p50 setup time > 90 seconds

## Appetite

- Time-box: 8 weeks for MVP validation release
- Team or capacity: 1 full-stack engineer + part-time product/design support
- Budget cap: use existing infrastructure only, no paid third-party gameplay backend

## MVP scope

- In scope (must-have slices):
  - Slice 1 - Create room, join by link, ready lobby with participant presence
  - Slice 2 - Core turn loop: track playback, placement, challenge timer, scoring, winner detection
  - Slice 3 - Results screen and rematch with same room participants
- Out of scope (explicit):
  - Persistent accounts and profiles
  - Match history and progression
  - Public matchmaking or ranking
  - In-app chat or voice
  - Native mobile apps
- Non-goals:
  - Song title recognition quiz mechanics
  - Social feed or community features

## Constraints

- Compliance or legal:
  - Respect provider API terms and regional licensing restrictions
  - No storage of provider credentials in client or persistent user profile
- Technical:
  - Real-time synchronous play only, no async turn model
  - Ephemeral identities and no database-backed account system in MVP
  - Single-node runtime for launch increment
- Dependencies:
  - Spotify OAuth app availability and quota
  - iTunes API availability for anonymous fallback playback
- Launch window:
  - Internal MVP validation window ends 2026-04-17

## Risks and rabbit holes

| Risk or rabbit hole                                        | Likelihood | Impact | Mitigation or acceptance                                                      |
| ---------------------------------------------------------- | ---------- | ------ | ----------------------------------------------------------------------------- |
| Provider quota or policy change blocks playback path       | medium     | high   | Keep provider abstraction and default iTunes fallback                         |
| Real-time instability degrades fairness in challenge phase | medium     | high   | Enforce authoritative server timer and broadcast state snapshots              |
| Year-guessing can feel punishing to casual players         | medium     | medium | Add optional difficulty settings and test hint mechanics in validation rounds |
| No persistent accounts reduces long-term retention options | high       | medium | Accept for MVP, defer identity persistence to post-validation                 |
| Over-investment in edge integrations delays MVP            | medium     | high   | Protect scope with strict non-goals and incremental release gates             |

## Solution options and tradeoffs (Stage 4)

| Option                                                 | Pros                                                              | Cons                                                      |
| ------------------------------------------------------ | ----------------------------------------------------------------- | --------------------------------------------------------- |
| A - Real-time web app with ephemeral sessions (chosen) | Lowest friction, shortest path to validation, no account overhead | Limited retention tooling, session state is transient     |
| B - Account-first platform with persistence            | Better long-term personalization and analytics                    | Higher delivery risk, slower MVP, larger security surface |
| C - Physical companion app only                        | Easier licensing and narrower backend scope                       | Does not solve setup friction root problem                |

Recommended option: A. It is the smallest reversible path to validate core gameplay engagement.

## Assumption register

| Assumption                                                  | Confidence | Validation owner | Validation step                                                  |
| ----------------------------------------------------------- | ---------- | ---------------- | ---------------------------------------------------------------- |
| 30-second preview is enough context for year placement      | high       | Max              | Run 10+ multiplayer sessions and measure placement participation |
| Room-link onboarding is sufficient without account creation | medium     | Max              | Track link-open to first-assumption conversion                   |
| 3-10 players can sustain synchronized turn pacing           | medium     | Max              | Observe timeout and disconnect rates in real sessions            |
| Provider fallback preserves session continuity              | medium     | Max              | Simulate provider failure during challenge phase                 |

## Open questions

| Question                                                             | Owner | Next step                                        | Deadline   | Status |
| -------------------------------------------------------------------- | ----- | ------------------------------------------------ | ---------- | ------ |
| What default challenge timeout maximizes fun without stalling turns? | Max   | Run A/B test at 6s, 8s, 10s                      | 2026-03-10 | open   |
| Should hints be enabled by default for first-time rooms?             | Max   | Prototype hint toggle and compare rematch rate   | 2026-03-17 | open   |
| Is 10-player upper bound stable on current single-node setup?        | Max   | Load-test concurrent rooms with max participants | 2026-03-24 | open   |
