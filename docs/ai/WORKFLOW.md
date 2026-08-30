# CI-first delivery workflow

Any capable model may implement, inspect, or repair the task. AI reviewer/verifier approvals are not part of merge eligibility.

## Mandatory delivery gate
- keep task scope locked
- validate exact changed paths
- run relevant targeted checks when available
- use only the latest exact PR head SHA
- require the official `Discourse Plugin` CI workflow to conclude GREEN on that exact head
- require any additional configured required Discourse-owned CI/check context to conclude GREEN too
- never reuse CI evidence from an older head SHA
- `NO_CI`, missing, skipped, pending, cancelled, neutral, stale-head, or failed required checks are not GREEN

If the latest exact head is GREEN and no unresolved security/schema/product/architecture blocker remains, the agent is authorized to merge without additional user confirmation. Prefer squash merge with `expected_head_sha` when supported.

## CI failure remediation
If CI fails, inspect the failing job, find the first actionable root cause, classify it as code/test-fixture/dependency/infrastructure, make the smallest justified repair, run targeted validation, push a new head, then evaluate CI again for that new SHA. Never weaken tests or expand product/architecture scope merely to make CI green.

Maximum automatic remediation: 3 repair rounds. After 3 unresolved rounds, or if a material architecture/security/schema/product decision is required, stop with `NEEDS_HUMAN` and report the current head, remaining failure, root cause, attempted repairs, and recommended next action.

If required CI is not configured or does not run, report `NO_CI`/`NOT_RUN`; do not call it GREEN.
