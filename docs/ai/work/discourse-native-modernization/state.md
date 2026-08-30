# Discourse-native modernization state

Current main at phase start: `902dee602b827b7332d1fa787870b5d1d0204fc2`.

Already merged before this phase:
- type-check bootstrap using current Discourse plugin TypeScript support
- admin FormKit/DModal/ui-kit/responsive modernization

Active phase: user Preferences > Cosmetics page.

Invariants:
- ownership/selection remain server-authoritative
- no route/API/schema/entitlement/public integration contract changes in this phase
- locale keys remain stable
- all existing selection/showcase behavior must remain covered

Merge gate: exact PR head + official Discourse Plugin CI GREEN; no stale-head result is accepted.
