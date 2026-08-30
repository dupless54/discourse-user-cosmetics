Goal: modernize the cosmetics admin form with current Discourse FormKit/DModal/responsive conventions.
Allowed paths: admin form/page/modal components, admin stylesheet, focused frontend tests, locales only if needed.
Relevant context: preserve all existing admin API payloads, upload/layer/owner flows, and server-authoritative authorization.
Acceptance: FormKit owns core metadata fields; delete uses DModal; no hover-only actions; official viewport helpers replace ad-hoc breakpoints where practical; no backend/schema change.
Validation: focused QUnit via official plugin CI; exact changed paths; exact-head workflow GREEN required.
Risk: T1 routine frontend refactor; escalate only if an upstream API mismatch forces server/public-contract changes.
Effort tier: T1.
Escalation trigger: FormKit/DModal incompatibility, API payload drift, or test evidence of behavior change.
