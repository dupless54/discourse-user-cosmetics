# Discourse-native modernization progress

## Completed
- [x] Current Discourse type-check CI bootstrap merged.
- [x] Admin forms moved to FormKit/DModal/ui-kit and current responsive helpers.
- [x] Preferences picker/showcase editor moved to current ui-kit and direct `discourse-i18n`.
- [x] Preferences cosmetic tabs use keyboard-correct tab semantics and named container breakpoints.
- [x] Preferences/showcase QUnit coverage and exact-head CI are GREEN and merged.
- [x] Profile/user-card effects use supported Plugin API/outlets with scoped modifier lifecycle.
- [x] Profile-effect global `<style>` injection and portal selector mismatch removed.
- [x] Profile/user-card phase exact-head Typecheck/QUnit/RSpec/lint CI GREEN and merged.
- [x] Nameplate presentation is scoped to the mounted Discourse user-card/profile surface.
- [x] Nameplate global `<style>` injection removed with focused teardown/live-sync QUnit coverage.
- [x] Nameplate exact-head Typecheck/QUnit/RSpec/lint CI GREEN and merged.
- [x] Client/admin callers use the current `discourse-i18n` entry point directly.
- [x] Current-user header avatar frame uses the supported `user-dropdown-button__after` outlet instead of a global style injection.
- [x] Header-frame exact-head Typecheck/QUnit/RSpec/lint CI GREEN and merged.
- [x] User-card avatar frames render through `user-card-avatar-flair` with scoped lifecycle CSS.
- [x] Profile avatar frames render through `user-profile-avatar-img-wrapper` with scoped lifecycle CSS.
- [x] Generated user-card/profile avatar selectors removed from `frames.css`.
- [x] Profile/user-card avatar-frame exact-head Typecheck/QUnit/RSpec/lint CI GREEN and merged.
- [x] Post avatar frames use the core `post-avatar-class` value transformer without expanding post serializer payloads.
- [x] Generated post-frame CSS is keyed by stable numeric user-id classes instead of username/`:has(img.avatar)` selectors.
- [x] Avatar-frame-only username changes no longer churn the shared stylesheet cache identity.
- [x] Post avatar-frame exact-head Typecheck/QUnit/RSpec/lint CI GREEN and merged.
- [x] Final admin caller migrated off the transitional `duc-i18n` helper.
- [x] Obsolete `assets/javascripts/discourse/lib/duc-i18n.js` removed after exact-head CI GREEN and merged.
- [x] Plugin routes moved to an isolated Rails engine while preserving public/admin route contracts.
- [x] App models/controllers now load through the engine; Phase 9 exact-head Typecheck/QUnit/RSpec/route/boot/Zeitwerk CI GREEN and merged.
- [x] Split integration extensions normalized to Zeitwerk-compatible modules while preserving the public `Integration` contract/constants.
- [x] Plugin `lib/` now autoloads through the isolated engine; manual library requires removed.
- [x] Phase 10 exact-head Typecheck/QUnit/RSpec/lint/boot/Zeitwerk CI GREEN and merged.

## Active native nameplate transformer phase
- [x] Verify current Discourse `poster-name-class` and `mentions-class` value transformers in core.
- [x] Add stable numeric user-id class transformers for post author names and cooked mentions.
- [x] Replace generated username/data-user-card/`:has()` nameplate selectors with transformer-backed classes.
- [x] Remove obsolete username-change stylesheet invalidation now that both generated CSS kinds use stable numeric identities.
- [x] Preserve existing entitled-selection filtering and image/gradient presentation semantics.
- [x] Add focused QUnit unit coverage for both class transformers.
- [x] Add RSpec coverage proving generated nameplate CSS no longer depends on username DOM selectors or rename-driven cache churn.
- [ ] Official exact-head Discourse Plugin CI GREEN, including Typecheck, lint, QUnit, RSpec, build, annotations, and boot/Zeitwerk checks.
- [ ] Merge.

Next after merge: continue thin-controller/service-object modernization in bounded phases, keeping public integration contracts and server-authoritative ownership/selection behavior unchanged.
