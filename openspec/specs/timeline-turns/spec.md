# Timeline Turns

Current Songy behavior at `72f5395`. The current point-scoring challenge differs from Hitster Original.
[The rules reference](../../../docs/hitster-original-reference.md) records the publisher source.

## Purpose

Describe the current turn, placement and result rules for the Songy game.

## Requirements

### Requirement: Ordered timeline validation

The system SHALL treat a submitted slot as chronologically correct when the track year is greater than or equal to the
preceding year and less than or equal to the following year.

#### Scenario: Place a track beside one from the same year

- **WHEN** a submitted slot borders a track with the same year and preserves the order on its other side
- **THEN** the placement is correct

Historical evidence: `265ac82`, `571da00`, `9b0be61`, `f4ef06c`.

### Requirement: Current turn phases

The system SHALL progress a turn through waiting, ready, challenging and results phases, with an authoritative server
deadline for the challenging phase.

#### Scenario: Challenge deadline expires

- **WHEN** the server challenge timeout fires
- **THEN** the game resolves the collected assumptions and enters results

Historical evidence: `e5b19bb`, `e193648`, `1a70e9d`, `5555d79`, `adc9b8e`.

### Requirement: Current assumption and score resolution

The system SHALL accept an active player's assumption before challenge and challenger assumptions during challenge. On
timeout, it SHALL award one point and add the track to the timeline of the first valid assumption encountered, if any.

#### Scenario: Resolve a turn with a valid assumption

- **WHEN** a challenge timeout occurs and at least one stored assumption is chronologically valid
- **THEN** one selected participant gains one point and the track is added to that participant's timeline

Historical evidence: `bd9dd67`, `c650715`, `dbe39ad`, `2e45051`, `c95aaed`.

### Requirement: Current score-based ending

The system SHALL mark a game finished after a participant reaches the configured maximum score and the results phase is
advanced.

#### Scenario: Advance results after target score

- **WHEN** results are advanced after a score reaches ten in a default room
- **THEN** the game enters the finished state

Historical evidence: `61fe0b6`, `03b47f9`, `6e34858`, `f654d2b`.
