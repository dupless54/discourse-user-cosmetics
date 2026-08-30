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

## Active client i18n cleanup
- [x] Preferences navigation imports `i18n` directly from `discourse-i18n`.
- [x] Admin delete modal imports `i18n` directly from `discourse-i18n`.
- [x] Admin list page imports `i18n` directly from `discourse-i18n`.
- [x] Remove the obsolete `globalThis.I18n` compatibility fallback; the temporary alias delegates to current `discourse-i18n`.
- [ ] Move the remaining large admin form from the transitional alias to a direct `discourse-i18n` import.
- [ ] Official exact-head Discourse Plugin CI GREEN.
- [ ] Merge.

Next after merge: finish the last direct-i18n caller, audit remaining post/avatar-frame presentation, then continue backend route/Zeitwerk/service-object modernization.
