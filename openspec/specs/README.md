# Project specifications

## Planning profile

- Strategy: contract-first
- Depth: standard
- Mode: strict
- Last updated: 2026-02-25

## Stage-to-artifact mapping

| Stage                              | Artifact                                            | File                                              |
| ---------------------------------- | --------------------------------------------------- | ------------------------------------------------- |
| 0 - Intake gate                    | Intake notes + assumptions                          | [Product Brief](product-context/product-brief.md) |
| 1 - Scope and constraints          | Scope, constraints, non-goals                       | [Product Brief](product-context/product-brief.md) |
| 2 - Outcomes and metrics           | Business and user outcomes, success/failure metrics | [Product Brief](product-context/product-brief.md) |
| 3 - Problem framing                | Current state, pain, hypotheses                     | [Product Brief](product-context/product-brief.md) |
| 4 - Solution options and tradeoffs | Alternatives and recommendation                     | [Design Doc](architecture/design.md)              |
| 5 - Requirements and acceptance    | FR, NFR, AC, flows, instrumentation                 | [PRD](product-context/prd.md)                     |
| 6 - Architecture decisions         | Irreversible decisions                              | [ADR Index](architecture/decisions/README.md)     |
| 7 - Technical design synthesis     | Coherent architecture + contracts + C4              | [Design Doc](architecture/design.md)              |
| 8 - Delivery planning              | Product-level sequencing, rollout, rollback         | [Delivery Plan](product-context/delivery-plan.md) |

## Product branch

- [Product Brief](product-context/product-brief.md) - stage 0-3 discovery baseline
- [PRD](product-context/prd.md) - stage 5 requirements contract
- [Design Doc](architecture/design.md) - stage 4 and 7 synthesis, C4 diagrams, domain model, contracts
- [ADR Index](architecture/decisions/README.md) - stage 6 decisions

## Process branch

- [Delivery Plan (Product-level)](product-context/delivery-plan.md) - stage 8 sequencing and launch control

## Supporting technical references

All technical references (security, deployment, data flows) are consolidated in [Design Doc](architecture/design.md).

## Gameplay rule alignment

- [Hitster Original Rules Reference](gameplay-audit/references/hitster-original-reference.md) - publisher source, rule
  decisions and Songy differences
- [Hitster Original Rules Asset](../../assets/public/assets/rules/hitster-original-rules.pdf) - PDF snapshot generated
  from the publisher's rules page
- [Gameplay Commit Map](gameplay-audit/references/gameplay-commit-map.md) - retrospective delivery evidence and full
  feature-commit index
- [OpenSpec Rule-Alignment Change](../changes/align-gameplay-with-hitster-original/proposal.md) - proposed behavior,
  design and implementation tasks
