## MODIFIED Requirements

### Requirement: Ordered timeline validation

The system SHALL validate a submitted slot on the server against the player's timeline before reveal. A track year is
valid when it preserves nondecreasing order, including either adjacent position beside an equal-year card. Invalid
indices SHALL be rejected rather than clamped.

#### Scenario: Place a track beside one from the same year

- **WHEN** a track is placed immediately before or after a card with the same year and the full timeline remains ordered
- **THEN** the placement is correct

#### Scenario: Out-of-range slot

- **WHEN** a player submits a slot outside the timeline's available positions
- **THEN** the server rejects the action and leaves the turn unchanged

## REMOVED Requirements

### Requirement: Current turn phases

**Reason**: The timed assumption phase is specific to the current Songy game and does not express Original card
placement and reveal. **Migration**: Use the active placement, challenge and reveal states below for new rule-aligned
rooms.

### Requirement: Current assumption and score resolution

**Reason**: Selecting one valid assumption from a position map does not implement token-backed challenges or Original
card ownership. **Migration**: Replace assumptions and point mutation with explicit active placement, ordered challenges
and one card-recipient decision.

### Requirement: Current score-based ending

**Reason**: Original victory depends on correctly acquired cards, not a separate point score. **Migration**: Derive
progress from qualifying timeline cards under the rule matrix finalized in task 1.2.

## ADDED Requirements

### Requirement: Original turn and reveal

The system SHALL select one active player, hold the track answer private, accept one active placement, accept eligible
challenges before reveal and then resolve the card exactly once. An incorrect unclaimed card SHALL be discarded.

#### Scenario: Active placement is correct

- **WHEN** the active placement preserves the chronological timeline order at reveal
- **THEN** the active player keeps the card even if a challenger chose another valid equal-year slot

#### Scenario: Active placement is wrong

- **WHEN** the active placement is wrong and no eligible challenge is correct
- **THEN** the card is discarded and no player gains a card

### Requirement: Ordered token challenges

In token mode, the system SHALL charge one token for each accepted challenge, reserve distinct challenge slots on the
active player's pre-reveal timeline and order challenges by server acceptance. If the active placement is wrong, the
first correct challenge SHALL receive the card.

#### Scenario: Competing correct challenges

- **WHEN** two players submit different correct slots before reveal while the active placement is wrong
- **THEN** the first accepted correct challenger receives the card and both spent tokens remain spent

#### Scenario: Duplicate challenge slot

- **WHEN** a second challenger submits a slot already reserved for this turn
- **THEN** the server rejects the challenge without consuming a token

### Requirement: Token economy

In token mode, each player SHALL start with two tokens, never hold more than five, spend one to skip their current song,
spend three to acquire a card without guessing, and gain one for correctly identifying both title and artist on their
turn, even if their placement is wrong. In a room without tokens, token actions SHALL be unavailable.

#### Scenario: Earn a token after a wrong placement

- **WHEN** the active player correctly identifies title and artist but places the card incorrectly
- **THEN** the player gains one token up to the cap and does not gain the placed card

#### Scenario: Retry a token action

- **WHEN** a client retries the same accepted token action for the same turn
- **THEN** the action has no second effect on balance or cards

### Requirement: Card-count victory

The system SHALL finish when one player first has ten qualifying cards under the finalized Original rule matrix. It
SHALL resolve card ownership and the winning state atomically before another turn can start.

#### Scenario: Gain the tenth card

- **WHEN** a player receives the card that brings their qualifying count to ten
- **THEN** the game finishes with that player as the winner and no next turn starts
