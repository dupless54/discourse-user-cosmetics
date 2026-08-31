# Post avatar frame phase 7 state

## Parent
- Base branch: `main`
- Base commit: `f098d432b157e88aa604779c1ad3256e26c8941f`

## Official Discourse source baseline
Validated against `discourse/discourse@768a4ed1cd8e6742fe1c1340a9c4ab01318285ec`.

- `frontend/discourse/app/components/post/avatar.gjs`
  - calls the `post-avatar-class` value transformer
  - applies returned classes to the native `.topic-avatar` host
  - transformer context includes `post` and `user`
- `frontend/discourse/tests/integration/components/post/avatar-test.gjs`
  - demonstrates `api.registerValueTransformer("post-avatar-class", ...)`
  - confirms returned classes land on `.topic-avatar`
- `docs/developer-guides/docs/03-code-internals/23-transformers.md`
  - current public API is `api.registerValueTransformer`
  - value transformers receive `{ value, context }` and must return the transformed value

## Decision
Do not add cosmetics to the post serializer. The post model already exposes `user_id`, and core exposes a stable avatar-class transformer. The plugin adds `duc-avatar-frame-user-<id>` to the native post avatar host and keeps the entitled image mapping in the existing cached generated stylesheet.

This avoids:
- per-post cosmetics serializer/cache lookups
- expanding topic-stream JSON payloads
- username-derived selectors
- `:has(img.avatar)` dependency for avatar frames

## Phase scope
- Register the native `post-avatar-class` transformer.
- Generate post avatar-frame CSS against the numeric transformer class.
- Remove the old username/`:has(img.avatar)` avatar-frame selectors and unused generic avatar-frame target rules.
- Preserve nameplate selectors unchanged in this phase.

## Invariants
- No entitlement, selection, serializer payload, route/API/schema, upload, grant/revoke, Store integration, or authorization behavior changes.
- User-card/profile/header frame presentation remains on the previously migrated native outlets.
- `frames.css` remains because post frame image mapping and nameplate presentation still use the generated stylesheet.

## Gate
Do not merge a changed head unless the official Discourse Plugin workflow is GREEN for that exact head, including Typecheck, lint, frontend QUnit/build, backend RSpec/boot and annotations.
