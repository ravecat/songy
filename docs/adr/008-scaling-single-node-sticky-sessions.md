# ADR-008: Single-Node Scaling Strategy

## Status

accepted

## Context

Game state lives in-memory (ADR-002), tokens live in ETS (ADR-007). All state is node-local. Horizontal scaling requires
distributed state management which adds significant complexity. Need to decide the scaling approach for MVP and define
the migration path.

## Options

- **Distributed Erlang + Horde** - transparent process distribution across nodes. But adds split-brain scenarios,
  network partition handling, and distributed state consistency challenges. Premature for a product that hasn't
  validated its core gameplay loop.

- **External state store (Redis) + sticky sessions** - moves state out of BEAM processes. Breaks the in-memory design
  (ADR-002) and adds external dependency + serialization overhead on every state access.

- **Single node with vertical scaling** - BEAM handles thousands of concurrent processes efficiently. Vertical scaling
  (more CPU/RAM) before distribution. Simple deployment, no coordination complexity.

- **Sticky sessions via load balancer + multiple nodes** - multiple independent nodes, each handling its own games.
  Requires WebSocket affinity at the load balancer. But no cross-node game discovery and provider state not shared.

## Decision

Run on a single BEAM node for MVP. The BEAM VM handles concurrent game sessions efficiently via lightweight processes.
Vertical scaling (more CPU/RAM) before introducing distribution complexity.

## Consequences

- (+) No distributed state coordination complexity
- (+) No split-brain scenarios
- (+) Simple deployment - single process, single node
- (+) BEAM handles thousands of concurrent game sessions on one node
- (-) Single point of failure - node crash loses all active games
- (-) Upper bound on concurrent games limited by single machine resources
- (-) Future horizontal scaling requires significant architecture changes (Horde, CRDT, or external state)

## Migration Path

When single-node capacity is insufficient:

1. Add Horde for distributed process registry
2. Move ETS to distributed store or Mnesia
3. Add load balancer with WebSocket affinity
