# ADR-001: Elixir/Phoenix as Runtime Platform

## Status

accepted

## Context

The application is a real-time multiplayer game (2-8 players per room) with stateful sessions lasting 15-60 minutes,
timed turn phases, and concurrent mutations from multiple players. Key technical requirements:

- Concurrent isolated game sessions (each room is independent)
- Serialized access to shared state within a room
- Fault isolation - a bug in one room must not affect others
- Built-in real-time communication primitives
- Lightweight session lifecycle management (create, run, cleanup)

## Options

- **Node.js + Socket.io/Colyseus** - largest ecosystem, single language with frontend. But single-threaded event loop
  with no process isolation - uncaught exception crashes all rooms. Stateful rooms require a framework (Colyseus) that
  emulates actor-like behavior on top of a runtime that doesn't natively support it. Worker threads are too heavy for
  per-room isolation.

- **Go + goroutines** - fast, compiled, cheap concurrency primitives. But goroutines lack mailboxes, state isolation,
  and supervision. Per-room state management requires manual channel + select loops. No built-in restart/recovery
  strategy - all supervision logic is hand-rolled.

- **Elixir/Phoenix (BEAM VM)** - lightweight processes with isolated heap and mailbox (native actor model). Built-in
  fault isolation ("let it crash"), native real-time communication primitives. Smaller community and harder hiring.

- **Rust + Actix** - actor model with maximum performance. Development velocity ~3x slower for a party game where
  sub-millisecond latency is irrelevant.

## Decision

Elixir/Phoenix on the BEAM VM. The core problem - isolated stateful concurrent sessions with lifecycle management - maps
directly to BEAM's native primitives. No framework or library needed to emulate this; it's the foundation of the
platform.

The tradeoff (smaller ecosystem, harder hiring) is acceptable for a small team where the primary constraint is
development speed per engineer, not team size.

## Consequences

- (+) Each game room is a process with isolated state and mailbox - zero shared-memory bugs
- (+) Supervisor trees provide fault isolation and automatic recovery
- (+) Phoenix Channels, Presence, PubSub are built-in - no external real-time dependencies
- (+) Path to distribution (Distributed Erlang) if horizontal scaling is needed later
- (-) Smaller talent pool compared to Node.js/Go
- (-) Smaller library ecosystem - some integrations require custom code
- (-) Steeper learning curve for engineers unfamiliar with functional programming and OTP
