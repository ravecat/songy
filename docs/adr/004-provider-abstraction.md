# ADR-004: Pluggable Music Provider Abstraction

## Status

accepted

## Context

The game requires music tracks with preview playback and metadata (title, artist, year). Music comes from external
streaming service APIs. Reliance on a single provider creates a single point of failure - rate limits, account blocks,
API deprecation, or regional restrictions can take down the entire product.

Different environments have different needs: development requires zero-config setup, production requires reliable
throughput.

## Options

- **Hardcoded single provider (iTunes/Apple Music)** - simplest implementation. But no fallback if the provider blocks
  us or changes terms. Switching requires rewriting every call site.

- **If/else multi-provider** - conditionals scattered through game logic.
  `if provider == :apple do ... else if provider == :spotify do ...`. Adding or removing a provider means touching game
  logic.

- **Protocol-based abstraction** - define a contract that each provider implements. Game logic works with a common track
  structure only - provider-agnostic. Switching or adding a provider = implementing the contract, no changes to game
  code.

## Decision

Protocol-based provider abstraction with a normalization layer.

A `Songy.Boundary.Provider` protocol defines what any music service must implement: `ensure/1`, `start_playback/2`,
`pause_playback/1`, `search_random_track/1`, `search/2`. A `Songy.Core.Trackable` protocol converts provider-specific
responses into a common `Track` struct. Game logic never touches provider-specific data.

Provider structs are stored per-user in ETS and determine track source + playback method. iTunes serves as zero-config
default for development and fallback.

## Consequences

- (+) Provider failure is recoverable - switch to fallback without code changes
- (+) Game logic is provider-agnostic - works with Track struct
- (+) Adding a new provider = implementing protocol, no changes to game code
- (+) iTunes as zero-config dev/fallback provider removes setup friction
- (+) Protocol cost is minimal (~20 lines) - not speculative abstraction
- (-) Each provider has different auth complexity (none vs JWT vs OAuth)
- (-) Track metadata varies between providers - normalization via Trackable adds a layer
- (-) Preview quality and length may differ between providers (30s preview vs full track)

## Code References

- `lib/songy/boundary/provider.ex` - Provider protocol
- `lib/songy/core/trackable.ex` - Track normalization protocol
- `lib/songy/core/provider/spotify.ex` - Spotify struct
- `lib/songy/core/provider/apple.ex` - Apple struct
- `lib/songy/core/provider/itunes.ex` - iTunes struct
- `lib/songy/boundary/provider/spotify.ex` - Spotify implementation
- `lib/songy/boundary/provider/apple.ex` - Apple implementation
- `lib/songy/boundary/provider/itunes.ex` - iTunes implementation
