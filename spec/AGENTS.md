# User Cosmetics backend specs

- Keep request specs focused on authentication, staff authorization, parameter validation, response contracts, non-enumeration/privacy behavior, and explicit serialization.
- Add focused service specs when business actions move into Discourse service objects; cover policy/contract failures, transaction boundaries, and important side effects without duplicating every request-spec assertion.
- Add model specs only for meaningful model-owned invariants/scopes/callbacks; do not move controller/service responsibilities into model tests for convenience.
- Use system specs for end-to-end UI workflows only when browser integration materially improves confidence over QUnit/request specs, and follow current Discourse system-spec helpers/page objects.
- For JSON responses, assert the intended field contract and ensure internal ActiveRecord attributes cannot leak through implicit serialization.
- Keep fixtures/factories minimal and deterministic. Preserve idempotency and ownership/selection invariants in tests involving grants, revokes, defaults, or deletions.
- Run targeted RSpec first, then the official Discourse Plugin CI. Never claim skipped/not-run checks as GREEN.
- Upstream references live in `docs/ai/OFFICIAL_DISCOURSE_GUIDANCE.md`; read only the relevant backend/testing sections when needed.
