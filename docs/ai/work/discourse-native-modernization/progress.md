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

## Active nameplate phase
- [x] Replace client-side global nameplate `<style>` injection with a scoped Ember modifier.
- [x] Target only the current Discourse user-card/profile name node.
- [x] Keep static presentation in plugin SCSS and only the validated cosmetic background dynamic.
- [x] Remove classes/background during modifier teardown so presentation cannot leak between cards.
- [x] Update live-sync tests for DOM-scoped nameplate rendering.
- [x] Add focused QUnit coverage for profile and user-card targets plus cleanup.
- [ ] Official exact-head Discourse Plugin CI GREEN.
- [ ] Merge.

Next after merge: audit remaining post/avatar-frame presentation and legacy client helpers, then continue backend route/Zeitwerk/service-object modernization.
