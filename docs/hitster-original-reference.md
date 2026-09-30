# Hitster Original rules reference

## Purpose and source

Use the publisher's [Hitster Original rules](https://hitstergame.com/en-nl/pages/how-to-play-original) as the source for
future gameplay design and result-validation tests. The publisher's
[product page](https://jumboplay.com/en-gb/products/hitster-uk-edition-1110100132) links to those rules. Reviewed on
2026-09-30. Recheck the live rules before implementing a rule change because the publisher may revise them.

The current official instructions are a web page. The publisher-hosted
[2021 Print-and-Play PDF](https://nordics.hitstergame.com/wp-content/uploads/2021/06/HITSTER-Print-and-Play.pdf) is a
deck of printable cards that points to separate instructions; it is not the rules for the current Original edition. Do
not use it as a result-validation fixture. No current Original-rule PDF was found on the publisher's linked download
pages, so there is no suitable PDF to add to public assets.

## Rule decisions to encode

| Area           | Publisher rule                                                                                                                                                                                                                                 | Decision needed for a digital game                                                                                  |
| -------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| Setup          | Each player or team starts with one visible card; the oldest drawn card determines the first player; play then proceeds clockwise.                                                                                                             | Decide whether the initial card counts toward the ten-card victory threshold and how to model teams.                |
| Placement      | The active player chooses a slot on their timeline; the card stays only when its year preserves chronological order. Equal-year cards may be adjacent in either order.                                                                         | Validate the submitted slot on the server against the pre-reveal timeline and immutable track year.                 |
| Reveal         | An incorrectly placed card is discarded.                                                                                                                                                                                                       | Record the final placement, outcome and recipient before starting another turn.                                     |
| Victory        | The first player or team to place ten cards correctly wins.                                                                                                                                                                                    | Define the digital boundary for simultaneous actions around the winning reveal.                                     |
| Tokens         | Tokens are optional for a simpler game. With tokens, players start with two and may hold at most five.                                                                                                                                         | Make token mode an explicit game rule, rather than silently applying token effects to all rooms.                    |
| Token actions  | One token skips the current song on the active player's turn; three buy a card without guessing; one stakes a challenge on an opponent's placement before reveal.                                                                              | Define ordering, authorization and atomic token consumption for competing actions.                                  |
| Challenge      | The earliest challenger chooses a slot on the active player's timeline; later challengers must choose distinct slots. A challenger only takes the card when the active placement is wrong and the challenge is right. Spent tokens leave play. | Define a deterministic ordering mechanism for real-time requests and the winner when multiple challenges are valid. |
| Token earning  | On their turn, a player earns one token for naming both title and artist correctly, even if their placement is wrong.                                                                                                                          | Decide whether text recognition is in scope and how names or aliases are judged.                                    |
| Advanced modes | Pro additionally requires title and artist; Expert also requires the exact year; Cooperative uses a shared timeline and a token-loss condition.                                                                                                | Treat these as later modes unless explicitly selected for this delivery.                                            |

These are paraphrases for planning, not a replacement for the publisher's instructions. The publisher states that its
physical game requires HITSTER cards; Songy's independent digital track catalog and rules need an explicit product and
rights decision before claiming exact HITSTER compatibility.

## Existing Songy differences

The current [PRD](prd.md) specifies a timed challenge phase, parallel assumptions and a point for one correct
participant. The implemented state machine follows that model. Hitster Original instead resolves ownership of one card
after the active placement and any token-backed challenges. Current Songy scores and timelines must therefore be treated
as existing behavior, not as evidence of Original-rule compliance.
