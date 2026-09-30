## MODIFIED Requirements

### Requirement: Ephemeral room creation

The system SHALL create an in-memory room with a shareable identifier, an owner, two to ten allowed participants, a
fixed Original ten-card goal and an explicit token-mode setting. It SHALL validate settings before creating the room.

#### Scenario: Create a room

- **WHEN** an owner submits valid room settings
- **THEN** the system creates a room with those settings and redirects to its room URL

#### Scenario: Reject invalid settings

- **WHEN** an owner submits a participant limit outside the supported range
- **THEN** no room is created and the owner receives a field-level error

### Requirement: Presence and room state

The system SHALL attach an ephemeral identity to a connected user, broadcast viewer-safe room snapshots and preserve an
existing participant's identity across reconnection.

#### Scenario: Join an existing room

- **WHEN** a user joins a valid waiting room channel
- **THEN** the user receives a viewer-safe snapshot and their permissions

#### Scenario: Reconnect during a turn

- **WHEN** an existing player reconnects to an in-progress room
- **THEN** the player receives their current game state without a second seed card or duplicate turn action

### Requirement: Owner-controlled start

The system SHALL allow the owner to start a waiting room with at least two players after giving each player one visible
seed card and establishing a deterministic initial turn order.

#### Scenario: Start from the lobby

- **WHEN** the owner starts a room with at least two players and usable seed tracks
- **THEN** every player has one seed card and the first turn starts with the owner-visible turn order

#### Scenario: Start with insufficient players

- **WHEN** the owner tries to start with fewer than two players
- **THEN** the room remains in the lobby and the server returns an actionable error

## REMOVED Requirements

### Requirement: Finished room and replay entry

**Reason**: The current replay entry creates an empty room and does not meet the same-participant rematch requirement.
**Migration**: Replace the entry with the rematch lifecycle below and keep old in-progress ephemeral rooms on the old
release until drained.

## ADDED Requirements

### Requirement: Player admission during play

The system SHALL reject new player identities after the game starts while allowing existing participants to reconnect.
It SHALL resolve an active player's disconnect without giving that player an unauthorized extra action.

#### Scenario: New user follows a link during play

- **WHEN** an unknown identity joins an in-progress room
- **THEN** the server denies player admission and does not modify the turn or timeline

#### Scenario: Active player disconnects

- **WHEN** the active player disconnects before placing a card
- **THEN** the room applies the documented disconnect policy and records whether the turn was skipped or resumed

### Requirement: Same-participant rematch

The system SHALL offer a finished-room rematch that retains the room's rule settings and offers each previous
participant a path to rejoin with a fresh seed timeline. No previous result or token balance SHALL carry into the new
game.

#### Scenario: Start a rematch

- **WHEN** the owner starts a rematch from the finished room
- **THEN** the same participants can enter a new lobby with the prior settings and a fresh game state

### Requirement: Action feedback

The room channel SHALL reply with structured errors for invalid, stale or unauthorized game actions.

#### Scenario: Submit an action after reveal

- **WHEN** a client submits a placement or challenge for a revealed turn
- **THEN** the server returns a stale-turn error and leaves the result unchanged
