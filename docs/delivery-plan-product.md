# Product Delivery Plan: Songy MVP

## Metadata

- Product: Songy MVP
- Scope level: product
- Planning horizon: 2026-02-16 to 2026-04-17
- Owner: Max
- Status: draft
- Related docs:
  - [Product Brief](product-brief.md)
  - [PRD](prd.md)
  - [Design Doc](design-doc.md)
  - [ADR Index](adr/README.md)

## Goal and release definition of done

- Goal:
  - Ship a stable MVP that validates core engagement loop for multiplayer timeline gameplay.
- Done when:
  - Users can create/join rooms, finish games, and trigger rematch with target onboarding and replay metrics.
  - Core failure modes have controlled degradation path and documented rollback.

## Release increments

| Increment                 | Outcome                                                     | Included slices or features                                          | Dependencies                                      | Owner | Target date | Exit criteria                                                      |
| ------------------------- | ----------------------------------------------------------- | -------------------------------------------------------------------- | ------------------------------------------------- | ----- | ----------- | ------------------------------------------------------------------ |
| R1 - Playable foundation  | End-to-end room lifecycle works in internal env             | Room creation, join by link, lobby presence, game start gating       | Stable channel join/auth path                     | Max   | 2026-03-01  | 10 consecutive internal runs without room-start blocker            |
| R2 - Core loop validation | Deterministic gameplay and scoring in multi-player sessions | Turn FSM, challenge timer, scoring, winner detection, results view   | Provider abstraction operational, timer stability | Max   | 2026-03-22  | 20 playtest matches completed with no critical scoring or sync bug |
| R3 - Launch readiness     | Controlled MVP validation launch                            | Rematch flow, telemetry events, provider fallback hardening, runbook | Spotify OAuth reliability, basic alerting         | Max   | 2026-04-17  | Metrics pipeline active, fallback tested, go/no-go gate approved   |

## Sequencing and critical path

- Critical path:
  - Room lifecycle stability -> gameplay determinism -> telemetry and fallback hardening -> launch gate
- Parallel workstreams:
  - Provider OAuth hardening can progress in parallel with gameplay UI polish
  - Documentation and operational runbook can be prepared during R2 validation sessions

## Cross-team dependencies

- Dependency: Spotify app setup and OAuth quota stability
  - Owner: Max
  - Needed by: R3
  - Fallback: iTunes-only launch mode for validation cohort
- Dependency: Internal playtest cohort availability
  - Owner: Product
  - Needed by: R2 and R3
  - Fallback: smaller but denser repeated sessions with same group

## Risks and mitigations

- Risk 1: Provider instability delays launch confidence and blocks music playback path
  - Mitigation: enforce iTunes-first fallback path by R2, gate Spotify rollout behind flag in R3
- Risk 2: Real-time sync bugs discovered late invalidate gameplay metric quality
  - Mitigation: introduce deterministic integration checks before R2 exit and freeze new scope after R2 starts
- Risk 3: Single-node capacity unknown under peak rooms
  - Mitigation: run load profile before R3 gate, define explicit concurrency ceiling and admission control fallback

## Release gates

- Gate 1 - Foundation complete
  - Entry criteria: R1 scope implemented and smoke-tested
  - Exit criteria: room creation/join/start path stable across supported browsers
- Gate 2 - Gameplay validated
  - Entry criteria: R2 core loop available in test environment
  - Exit criteria: scoring correctness and timer behavior validated in playtests
- Gate 3 - Launch readiness
  - Entry criteria: telemetry, fallback, and runbook in place
  - Exit criteria: launch metrics dashboard green and rollback drill completed

## Launch criteria and rollback

- Technical:
  - No Sev-1 defects in create/join/play/rematch path during final week
  - Provider fallback success path validated in staged failure scenario
  - Telemetry coverage for room lifecycle and turn resolution events is complete
- Product:
  - Playtest cohorts hit minimum match completion and rematch thresholds from brief
  - Reported onboarding friction stays within accepted threshold
- Rollback trigger:
  - Critical gameplay regression, provider outage without effective fallback, or onboarding failure beyond threshold
- Rollback validation:
  - Disable new room creation or force iTunes-only mode, verify no new critical errors for one full day of cohort usage
