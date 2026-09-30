## MODIFIED Requirements

### Requirement: Provider-backed track selection

The system SHALL select a track with a known canonical year and a usable playback source before opening a placement
turn. It SHALL avoid replaying a track already used in that room and bound retries when providers return unusable
candidates.

#### Scenario: Obtain the next track

- **WHEN** the room starts or advances after results and provider search succeeds
- **THEN** a playable selected track becomes the current track for the next turn

#### Scenario: Provider returns an unplayable candidate

- **WHEN** the chosen provider returns a track without a usable preview or full-track playback path
- **THEN** the system rejects that candidate and selects another before any player can place it

### Requirement: Provider choice and sessions

The system SHALL support the existing Spotify, Apple Music and iTunes providers, keep credentials server-side and use an
available configured provider when the selected source fails during track acquisition or playback.

#### Scenario: Resolve an anonymous user

- **WHEN** a user has no persisted provider session
- **THEN** provider resolution uses the configured default

#### Scenario: Primary provider fails during acquisition

- **WHEN** the primary provider cannot return a playable candidate
- **THEN** the system tries an available fallback and either starts a valid turn or returns a bounded provider error

### Requirement: Normalized track metadata

The system SHALL retain a canonical year, title and artist for result validation while withholding answer metadata from
players until reveal.

#### Scenario: Display a revealed track

- **WHEN** the turn reaches the committed result
- **THEN** clients can show the selected track's normalized metadata

#### Scenario: Reveal a track

- **WHEN** the server commits a turn result
- **THEN** it sends the canonical year, title and artist with the result to authorized room participants

## ADDED Requirements

### Requirement: Playback failure state

The system SHALL represent playback start, pause and failure states consistently across supported providers and prevent
scoring a track that players could not hear.

#### Scenario: Playback fails before placement

- **WHEN** playback cannot start for the current track
- **THEN** the room pauses the turn, keeps answer metadata private and offers a retry or replacement track

### Requirement: Private pre-reveal snapshots

The system SHALL project a game snapshot for each viewer so unrevealed year, title, artist and opponents' private
actions are not exposed in channel payloads.

#### Scenario: Receive a challenge-phase snapshot

- **WHEN** a player receives a snapshot before reveal
- **THEN** the payload excludes answer metadata and private actions that player is not allowed to see
