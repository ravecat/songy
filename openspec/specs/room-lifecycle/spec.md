# Room Lifecycle

Current Songy behavior at `72f5395`. This is a retrospective baseline, not a claim of Hitster Original compliance.
Historical commits identify the main delivery points; [the commit map](../../../docs/gameplay-commit-map.md) records the
wider sequence.

## Purpose

Describe the room lifecycle that the current Songy code delivers.

## Requirements

### Requirement: Ephemeral room creation

The system SHALL create an in-memory room with a shareable identifier, an owner, a maximum of eight participants and a
target score of ten when the owner requests `/create`.

#### Scenario: Create a room

- **WHEN** a user requests room creation
- **THEN** the system creates a room and redirects the user to its room URL

Historical evidence: `ed7ae88`, `2579fe5`, `9fd88cd`, `03b47f9`, `9d07a76`.

### Requirement: Presence and room state

The system SHALL attach an ephemeral identity to a connected user and broadcast room snapshots as presence or game state
changes.

#### Scenario: Join an existing room

- **WHEN** a user joins a valid room channel
- **THEN** the user receives the current game snapshot and permissions

Historical evidence: `2ca8433`, `7830e25`, `724822b`, `08dd207`, `e77b9b8`.

### Requirement: Owner-controlled start

The system SHALL authorize the room owner to start a waiting room and reject an unauthorized start in the game process.

#### Scenario: Start from the lobby

- **WHEN** the owner starts a waiting room and a track can be selected
- **THEN** the room enters an in-progress waiting turn

Historical evidence: `406509a`, `5f2325c`, `809abfe`.

### Requirement: Finished room and replay entry

The system SHALL show a final leaderboard when the game reaches its target score. The current replay entry creates a
separate empty room.

#### Scenario: Use replay after a game

- **WHEN** a participant uses the replay entry on the finished view
- **THEN** the application creates a new room without preserving participants or room settings

Historical evidence: `6e34858`, `58eecfc`, `f654d2b`.
