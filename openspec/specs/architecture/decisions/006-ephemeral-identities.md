# ADR-006: Ephemeral Identities

## Status

accepted

## Context

Users need to be identified within a game session - distinguished from each other, tracked on reconnect, associated with
scores. The product targets a party/social context where minimizing friction is critical: a group receives a link and
should be playing within seconds.

Spotify OAuth is required for music playback but serves as provider authorization, not as user identity in the system.

## Options

- **Mandatory registration (email/OAuth)** - enables persistent profiles, leaderboards, friend lists. But every
  registration step in a party context reduces conversion. One person in a group of six hitting a signup form can kill
  the session.

- **Optional accounts with anonymous fallback** - flexible, but creates two code paths for every feature (authenticated
  vs anonymous). For an app with two pages, this doubles complexity for marginal gain.

- **Fully ephemeral identities** - generate UUID, random name, and avatar on first visit. Store in cookie session. No
  persistence across sessions. Zero friction entry.

## Decision

Fully ephemeral identities. Each visitor gets a generated identity (unique ID, random name via `UniqueNamesGenerator`,
avatar via DiceBear API) on first visit. No persistence across sessions.

This aligns with the party game context where the barrier to entry must be as close to zero as possible. Features that
require persistent identity (leaderboards, history, friend lists) are out of MVP scope and can be added later without
rearchitecting - ephemeral now does not block accounts later.

## Consequences

- (+) Zero friction - open link, you're in the game
- (+) No auth infrastructure to build or maintain
- (+) No personal data stored - GDPR-friendly by default
- (+) Simplifies the entire stack - no user database, no password reset, no email verification
- (-) No continuity across sessions - player stats and history not tracked
- (-) Cannot implement cross-game features (leaderboards, friend lists) without a future ADR
- (-) Spotify re-auth required each new session (token not tied to persistent account)

## Code References

- `lib/songy/core/user.ex` - User struct with uuid, name, avatar_url
- `lib/songy_web/auth.ex` - `fetch_current_user/2` creates user on first visit
- `unique_names_generator` dependency in mix.exs
