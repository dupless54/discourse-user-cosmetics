# Client i18n helper cleanup phase 8 state

## Parent
- Base branch: `main`
- Base commit: `45f09e721421602eb78262f4c2c9b2ce387fcc55`

## Source baseline
Previous modernization phases moved every active client/admin caller to the current `discourse-i18n` entry point. Repository code search for `duc-i18n` returns no active caller, and the compatibility file itself states it should be removed once the final caller is migrated.

## Phase scope
- Delete the unused `assets/javascripts/discourse/lib/duc-i18n.js` compatibility wrapper.
- Update modernization progress documentation.

## Invariants
No client UI behavior, translations, routes, API/schema, serializers, entitlement, selection, uploads, grants/revokes, styling, or authorization behavior changes.

## Gate
Do not merge a changed head unless the official Discourse Plugin workflow is GREEN for that exact head, including Typecheck, lint, frontend QUnit/build, backend RSpec/boot and annotations.
