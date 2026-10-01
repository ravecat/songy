# ADR-003: Phoenix Channels for Real-Time Communication

## Status

accepted

## Context

All players in a room must see state changes instantly (new player joined, assumption made, scores revealed).
Communication must be bidirectional: clients push events (start_game, make_assumption, advance_turn), server pushes
state updates and timer ticks.

## Options

- **Polling** - simple to implement. But adds latency (poll interval), wastes bandwidth on empty polls, and scales
  poorly with number of players and rooms. Unacceptable for a timed 8-second challenge phase.

- **Server-Sent Events (SSE)** - server-to-client push with HTTP. But unidirectional - client events would still require
  separate HTTP requests. No built-in reconnection state management.

- **Phoenix Channels (WebSocket)** - bidirectional, built into the framework. Per-room topic (`room:{game_id}`). Phoenix
  Presence for tracking who's online. Built-in reconnection and heartbeat. PubSub integration for internal broadcasting.

- **Phoenix LiveView** - server-rendered real-time UI. But core UI requirements (Spotify Playback SDK, drag-and-drop
  timeline, audio visualization) are inherently client-side. LiveView hooks become a workaround.

## Decision

Phoenix Channels with a per-room topic (`room:{game_id}`). Server broadcasts full game state after every mutation;
clients subscribe via Svelte channel wrapper. Bidirectional: clients push events, server pushes state and timer.

## Consequences

- (+) Bidirectional - clients push events, server broadcasts state
- (+) Phoenix Presence for tracking who's online (participant join/leave)
- (+) Built-in reconnection and heartbeat
- (+) PubSub integration for internal broadcasting
- (-) Requires managing socket lifecycle on the client (connect, join, leave, error)
- (-) Not using LiveView means maintaining separate Svelte components for UI

## Code References

- `lib/songy_web/channels/room_channel.ex` - channel event handlers
- `lib/songy_web/channels/user_socket.ex` - socket configuration
- `assets/js/lib/channel.svelte.ts` - Svelte channel wrapper
