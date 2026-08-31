# Client i18n helper cleanup phase 8 state

## Parent
- Base branch: `main`
- Base commit: `45f09e721421602eb78262f4c2c9b2ce387fcc55`

## Source baseline
Current Discourse client/admin code imports `i18n` directly from `discourse-i18n`. The transitional plugin helper exists only to preserve the historical local `t(...)` call shape while callers are migrated.

## CI correction
The first exact-head official CI run exposed one remaining active caller that repository code search had missed:

`assets/javascripts/discourse/admin/components/user-cosmetics-layer-upload.gjs`

QUnit compilation failed because that component still imported `../../lib/duc-i18n` after the helper was deleted. The component now imports `i18n` directly as `t` from `discourse-i18n`, preserving all existing call sites and behavior. A follow-up repository search for `duc-i18n` returns no active caller.

## Phase scope
- Migrate the final layer-upload caller to direct `discourse-i18n`.
- Delete `assets/javascripts/discourse/lib/duc-i18n.js`.
- Update modernization progress documentation.

## Invariants
No client UI behavior, translations, routes, API/schema, serializers, entitlement, selection, uploads, grants/revokes, styling, or authorization behavior changes.

## Gate
Do not merge a changed head unless the official Discourse Plugin workflow is GREEN for that exact head, including Typecheck, lint, frontend QUnit/build, backend RSpec/boot and annotations.
