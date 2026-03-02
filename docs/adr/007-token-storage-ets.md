# ADR-007: Token Storage in ETS

## Status

accepted

## Context

Music provider credentials (Spotify access/refresh tokens, Apple Music tokens) need to be stored per user during a
session. Tokens are ephemeral - tied to sessions that have no persistence (ADR-006). The storage must support fast
concurrent reads (multiple game rooms querying provider state simultaneously) and transparent token refresh.

## Options

- **PostgreSQL** - durable, structured. But adds an external dependency for ephemeral data. The project has no database
  (ADR-002). Running postgres for token storage alone is overhead.

- **Cookie session** - already used for user identity. But Spotify tokens are sensitive (allow playback control) and
  cookies are sent to the client. Session cookie size is limited; multiple provider tokens may exceed it.

- **ETS table** - fast concurrent reads via public table, no process serialization bottleneck. Server-side only.
  Automatic cleanup on BEAM restart (ephemeral by design). Managed by a GenServer that owns the table.

- **Individual GenServer processes** - one process per user for tokens. Adds process overhead and complexity for a
  simple key-value lookup pattern.

## Decision

ETS table managed by `Songy.Providers` GenServer. Tokens are keyed by `user_id` and store the full provider struct
(Spotify, Apple, or iTunes). The GenServer owns the table; reads are direct ETS lookups (no GenServer bottleneck).
`ensure/1` checks token expiration and refreshes transparently.

## Consequences

- (+) Fast concurrent reads - ETS public table, no process serialization
- (+) Automatic cleanup when BEAM restarts (ephemeral by design)
- (+) Supports token refresh: `ensure/1` checks expiration and refreshes transparently
- (+) No database needed - aligns with ADR-002
- (-) Tokens lost on node restart - users must re-authenticate
- (-) No cross-node sharing without distributed ETS or external store
- (-) Default provider fallback (iTunes) when credentials are invalid or missing

## Code References

- `lib/songy/providers.ex` - GenServer + ETS table (`insert/2`, `lookup/1`, `ensure/1`, `update/2`, `remove/1`)
- `lib/songy_web/auth.ex` - `fetch_current_provider/2` reads from ETS
- `config/config.exs` - `default_provider: Songy.Core.Provider.ITunes`
