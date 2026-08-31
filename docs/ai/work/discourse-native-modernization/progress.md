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

## Active profile/user-card avatar-frame modernization
- [x] Render user-card avatar frames through the core `user-card-avatar-flair` outlet.
- [x] Render profile avatar frames through the core `user-profile-avatar-img-wrapper` outlet.
- [x] Scope frame CSS custom properties/classes to mounted Discourse avatar hosts with teardown cleanup.
- [x] Remove generated user-card/profile avatar selectors from `frames.css`; keep post presentation unchanged for now.
- [x] Add focused QUnit and Ruby coverage for the new surface boundary.
- [ ] Official exact-head Discourse Plugin CI GREEN.
- [ ] Merge.

Next after merge: audit the core `post-avatar` outlet and decide the post cosmetics payload/cache strategy before removing the remaining generated post-frame selectors. Then continue backend route/Zeitwerk/service-object modernization.
