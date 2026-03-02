# Planning Documentation

## Planning profile

- Strategy: contract-first
- Depth: standard
- Mode: strict
- Last updated: 2026-02-25

## Stage-to-artifact mapping

| Stage                              | Artifact                                            | File                                                       |
| ---------------------------------- | --------------------------------------------------- | ---------------------------------------------------------- |
| 0 - Intake gate                    | Intake notes + assumptions                          | [Product Brief](product-brief.md)                          |
| 1 - Scope and constraints          | Scope, constraints, non-goals                       | [Product Brief](product-brief.md)                          |
| 2 - Outcomes and metrics           | Business and user outcomes, success/failure metrics | [Product Brief](product-brief.md)                          |
| 3 - Problem framing                | Current state, pain, hypotheses                     | [Product Brief](product-brief.md)                          |
| 4 - Solution options and tradeoffs | Alternatives and recommendation                     | [Design Doc](design-doc.md)                                |
| 5 - Requirements and acceptance    | FR, NFR, AC, flows, instrumentation                 | [PRD](prd.md)                                              |
| 6 - Architecture decisions         | Irreversible decisions                              | [ADR Index](adr/README.md)                                 |
| 7 - Technical design synthesis     | Coherent architecture + contracts + C4              | [Design Doc](design-doc.md)                                |
| 8 - Delivery planning              | Product-level sequencing, rollout, rollback         | [Delivery Plan](delivery-plan-product.md)                  |

## Product branch

- [Product Brief](product-brief.md) - stage 0-3 discovery baseline
- [PRD](prd.md) - stage 5 requirements contract
- [Design Doc](design-doc.md) - stage 4 and 7 synthesis, C4 diagrams, domain model, contracts
- [ADR Index](adr/README.md) - stage 6 decisions

## Process branch

- [Delivery Plan (Product-level)](delivery-plan-product.md) - stage 8 sequencing and launch control

## Supporting technical references

All technical references (security, deployment, data flows) are consolidated in [Design Doc](design-doc.md).
