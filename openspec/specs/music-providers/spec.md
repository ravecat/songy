# Music Providers

Current Songy behavior at `72f5395`. This baseline describes provider selection and track acquisition; it does not imply
every adapter delivers audible playback in the browser.

## Purpose

Describe the current provider capabilities used by game sessions.

## Requirements

### Requirement: Provider-backed track selection

The system SHALL request a random track from the owner's resolved music provider when starting a game and when advancing
to another turn.

#### Scenario: Obtain the next track

- **WHEN** the room advances after results and provider search succeeds
- **THEN** the selected track becomes the current track for the next turn

Historical evidence: `f541382`, `306b019`, `e35073d`, `29241e9`.

### Requirement: Provider choice and sessions

The system SHALL support Spotify authorization and provider sessions, Apple Music catalog search and iTunes catalog
search. It SHALL resolve Apple Music as the configured default provider at this baseline.

#### Scenario: Resolve an anonymous user

- **WHEN** a user has no persisted provider session
- **THEN** provider resolution uses the configured default

Historical evidence: `cebee6b`, `6d9d1c1`, `2cd41af`, `9804abe`, `ef7dde5`, `9fae212`.

### Requirement: Normalized track metadata

The system SHALL represent a selected track with a year and display metadata for the game timeline and reveal view.

#### Scenario: Display a revealed track

- **WHEN** the turn reaches results
- **THEN** clients can show the selected track's normalized metadata

Historical evidence: `498510b`, `a52a0e2`, `d85c153`, `b63eb80`.
