# Bootstrap cosmetics reconciliation

- Goal: prevent stale equipped cosmetics from reappearing after a normal reload/new browser session.
- Allowed paths: frontend lifecycle sync, its tests, and this task packet only unless evidence requires expansion.
- Relevant context: main `e6c55378…`; PR #39 reconciles only after visibility/pageshow resume.
- Root symptom: header frame stays current while CSS-backed/forum surfaces revert until tab resume.
- Acceptance: normal boot immediately refreshes shared cosmetics CSS and reconciles current-user presentation from a cache-busted server request.
- Acceptance: resume/bfcache reconciliation remains intact and deduplicated.
- Acceptance: removing all cosmetics remains removed after reload.
- Security: server remains authoritative; no client entitlement decisions.
- Validation: Official Discourse Plugin CI exact head, especially frontend QUnit plus existing backend suite.
- Risk: T1 frontend lifecycle/cache fix; no schema, authorization, payment, or public contract changes.
- Merge: do not merge without explicit user authorization.
