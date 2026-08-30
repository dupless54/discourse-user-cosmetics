# Discourse-native modernization plan

Goal: bring every User Cosmetics surface onto current supported Discourse APIs and design conventions without changing entitlement or public integration semantics accidentally.

## Upstream gate
- Start version-sensitive work from the live Developer Guides Index.
- Verify task-specific APIs against current `discourse/discourse` core when needed.
- Current official docs/core override remembered or copied examples.

## Phases
1. Preferences page: picker + showcase editor; current ui-kit controls, direct `discourse-i18n`, correct tab semantics, container-responsive layout, focused QUnit.
2. Profile/user-card/post surfaces: audit presentation components and extension hooks; prefer Plugin API/outlets/Transformers over invasive core modification; ensure touch/keyboard parity.
3. Frontend platform cleanup: remove remaining legacy client imports/helpers where current public APIs exist; audit AppEvents/service usage and type coverage.
4. Styling/accessibility: migrate remaining relevant hardcoded breakpoints to `lib/viewport`/`lib/container`, keep theme variables/light/dark compatibility, improve BEM/state/focus patterns, remove hover-only essential actions.
5. Backend/data: audit Rails Engine/Zeitwerk structure, controller orchestration, service-object candidates, explicit serialization allowlists, authorization and asset/CSS safety.
6. Tests/compatibility: fill route/component/system-spec gaps, maintain real typecheck, exact-head official Discourse CI, and document any deliberate d-compat contract.

Each phase is a bounded PR. Merge only on the latest exact head after required CI is GREEN and no unresolved security/schema/public-contract blocker remains.
