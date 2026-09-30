## Context

The in-memory `Songy.Boundary.Game` GenStateMachine serializes room mutations. Today it resolves a timed contest by
selecting one valid assumption, incrementing a point score and appending the track to that participant's timeline. The
current [PRD](../../../docs/prd.md) describes this Songy-specific behavior; it is not the
[publisher's Original rules](../../../docs/hitster-original-reference.md). The default provider is Apple Music, and
rooms disappear with their process. No persistent game-state migration is required.

## Goals / Non-Goals

**Goals:**

- Make Original-mode placement, challenge, reveal, card ownership and victory deterministic and testable on the server.
- Keep unrevealed track metadata private, recover predictably from provider and connection failures, and expose action
  errors to the client.
- Retain an auditable outcome for each turn and provide a real rematch lifecycle.

**Non-Goals:**

- Pro, Expert, Cooperative, physical-card QR compatibility, persistent accounts or cross-node game state.
- Rewriting existing Git history or preserving compatibility with in-progress rooms across a rule-engine deployment.

## Decisions

### One authoritative state writer

Keep the room GenStateMachine as the writer for placements, token balances, challenge order and reveal. Every accepted
action carries a turn identifier and is applied at most once. The channel returns a structured success or error reply.
This reuses the existing isolation boundary and makes racing challenges resolve in server receipt order. A client-side
winner calculation would be easier to display but could diverge between participants.

### Explicit turn record and reveal boundary

Represent the active player, track identity, original timeline, final placement, ordered challenges, spent and earned
tokens, outcome and recipient in one turn record. Track year, title and artist remain server-only until reveal. The
server validates each slot against the pre-reveal timeline; a same-year slot is valid on either side of an equal-year
neighbor. Once reveal is committed, late placements and challenges are rejected. A card has one recipient at most and no
score is independently incremented: victory uses the count of qualifying timeline cards. The rule matrix must settle
whether the initial visible card and token-purchased cards qualify before this logic is implemented.

### Token mode is explicit

Support a simpler room mode without tokens and an Original token mode. In token mode, enforce initial balance two and
cap five. Spend one to skip the active song, one to challenge, or three to acquire a card without guessing. Award one
for a correct title-and-artist answer on the active player's turn, including a wrong placement. Treat tokens as
transactional state with challenge positions unique per turn. The exact text-answer policy must be decided before
implementation so metadata variants do not create arbitrary wins.

### Digital challenge ordering

The server accepts challenges in call order until reveal. The active player's correct placement takes precedence over
all challenges, including another valid same-year slot. If active placement is wrong, the first valid accepted challenge
receives the card; all accepted challenge tokens are spent. This is the closest deterministic mapping of the publisher's
"first to call" rule to a networked room. The trigger and minimum time for reveal remain an explicit product decision;
an automatic eight-second expiry is not a publisher rule.

### Session and provider boundaries

Only lobby participants get a seed card. After start, existing players may reconnect; new identities cannot enter as
players. A room snapshot is projected for the viewer: it shows the playable track reference where necessary but not
unrevealed answer metadata or other private submissions. Select a candidate only when its year and playback source are
usable. If acquisition or playback fails, retry or switch to an available configured source before opening the placement
phase, and report a bounded failure if no source works. Keep provider credentials server-side.

### Delivery sequence

First establish the rule decisions and golden rule cases. Then update core validation and turn data, FSM transitions,
channel contract and clients. Provider hardening and rematch follow the new state model. Finish with multi-client race
tests, failure paths, event capture and playtests. The OpenSpec tasks track this order. This keeps a failure in metadata
or playback from being mistaken for a scoring defect.

## Risks / Trade-offs

- [Publisher rules can change] -> retain the source URL and review date; rerun golden cases against the live
  instructions before implementation.
- [Track metadata can disagree with the game card year] -> define a canonical release-year policy and exclude ambiguous
  candidates until verified.
- [Network latency affects who challenges first] -> order only by server receipt and expose the accepted order in the
  result; document that this is a digital adaptation.
- [Optional token mode broadens state combinations] -> test both modes independently, including balance limits and
  duplicate requests.
- [Current sessions use another state shape] -> terminate or drain active ephemeral rooms at rollout and require clients
  to reload the new contract; rollback restores the previous release but not ended rooms.
- [Provider terms and game identity] -> verify that independent catalog playback and branding are permitted before a
  public release; the publisher says its physical game requires its cards.

## Migration Plan

1. Agree on unresolved product decisions and freeze a rule matrix with acceptance cases.
2. Implement the new turn model behind a release gate for newly created rooms; regenerate the AsyncAPI client contract
   together with server changes.
3. Drain or end old in-memory rooms during deployment, switch new rooms to the rule-aligned path and validate
   multiplayer sessions.
4. If critical scoring or playback defects appear, stop new rule-aligned rooms, restore the previous release and start
   fresh rooms after rollback.

## Open Questions

- Is Original with optional tokens the intended product, or should Songy keep its timed point contest as a distinct
  mode?
- Does the initial face-up card count toward the ten correctly placed cards? This design assumes no.
- What action closes the challenge window in a remote session, and how much time must every connected player have to
  challenge?
- How are title and artist answers normalized and disputed when provider metadata differs from the publisher's card?
- Are teams, an owner-controlled DJ and mixed difficulty levels needed in the first rule-aligned release?
