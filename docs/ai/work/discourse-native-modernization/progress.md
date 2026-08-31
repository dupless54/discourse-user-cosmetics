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

## Active Rails engine / route autoload phase
- [x] Add a root-loaded isolated `DiscourseUserCosmetics::Engine` following the current official plugin skeleton.
- [x] Move plugin-owned user/admin JSON routes into `config/routes.rb` on the engine.
- [x] Preserve the core Admin Plugins page route and both native preferences aliases on `Discourse::Application` before the root engine mount.
- [x] Remove manual `require_relative` loading for app models/controllers so the engine owns app autoloading.
- [x] Keep library requires explicit for now because `integration_contract.rb` and `showcase_integration.rb` intentionally reopen `Integration` and are not yet Zeitwerk filename/constant compatible.
- [ ] Official exact-head Discourse Plugin CI GREEN, including Zeitwerk reload/eager-load and existing request-route coverage.
- [ ] Merge.

Next after merge: normalize the split `Integration` extension files so `lib/discourse_user_cosmetics` can join the engine autoload path safely, then continue thin-controller/service-object modernization and the remaining generated nameplate selector audit as separate phases.
