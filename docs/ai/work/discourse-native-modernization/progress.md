# Discourse-native modernization progress

## Completed
- [x] Current Discourse type-check CI bootstrap merged.
- [x] Admin forms moved to FormKit/DModal/ui-kit and current responsive helpers.
- [x] Preferences picker/showcase editor moved to current ui-kit and direct `discourse-i18n`.
- [x] Preferences cosmetic tabs use keyboard-correct tab semantics and named container breakpoints.
- [x] Preferences/showcase QUnit coverage and exact-head CI are GREEN and merged.

## Active profile/user-card phase
- [x] Keep current supported Plugin API/outlet integration; no invasive core overrides added.
- [x] Move profile showcase and user-card message copy to direct `discourse-i18n`.
- [x] Replace profile-effect global `<style>` injection with effect-lifetime scoped host/card classes.
- [x] Fix profile-effect portal class mismatch with BEM-style back/front modifiers.
- [x] Restore temporary positioning changes during modifier teardown.
- [x] Extend reduced-motion and active-effect cleanup QUnit coverage.
- [ ] Official exact-head Discourse Plugin CI GREEN.
- [ ] Merge.

Next after merge: scope nameplate presentation without global style injection, then audit remaining post/user-card presentation and legacy client helpers.
