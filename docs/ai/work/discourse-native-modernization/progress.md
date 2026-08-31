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

## Active compatibility cleanup
- [x] Confirm no active caller imports the transitional `duc-i18n` compatibility helper.
- [x] Remove `assets/javascripts/discourse/lib/duc-i18n.js`.
- [ ] Official exact-head Discourse Plugin CI GREEN.
- [ ] Merge.

Next after merge: continue backend route/Zeitwerk/service-object modernization in small behavior-preserving phases, then separately audit the remaining generated nameplate selector path.
