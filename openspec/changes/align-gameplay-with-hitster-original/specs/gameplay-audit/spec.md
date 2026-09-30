## ADDED Requirements

### Requirement: Immutable round outcome

The system SHALL retain an outcome record in the room process for each completed turn until that room ends. The record
SHALL contain the turn and track identifiers, active placement, ordered accepted challenges, token changes, validation
result, card recipient or discard, and reveal time. A repeated reveal SHALL return the same outcome without a second
mutation.

#### Scenario: Retry reveal after completion

- **WHEN** a reveal command is repeated for an already resolved turn
- **THEN** the server returns the recorded outcome without changing a timeline or token balance

### Requirement: Gameplay instrumentation

The system SHALL emit structured events for room creation and join, game and turn start, accepted action, reveal, game
finish, rematch and provider fallback without publishing credentials or hidden answer data before reveal.

#### Scenario: Provider fallback

- **WHEN** a turn uses a fallback provider after a primary source fails
- **THEN** an event records the room, source change and failure category without including provider credentials
