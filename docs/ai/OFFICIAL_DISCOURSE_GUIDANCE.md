# Official Discourse Developer Guidance

Verified against official Discourse Meta developer documentation on 2026-08-30. This is a routing/reference document, not mandatory preload context.

## Authority and freshness

- Current repository source/tests remain authority for this plugin.
- For Discourse platform conventions, prefer current `discourse/discourse` core source, the current official plugin skeleton, and official Meta developer guides.
- If an older guide conflicts with current core/skeleton source, follow current source and record the compatibility reason when relevant.
- Do not cargo-cult old examples. Several long-lived Meta topics have been updated over time while old replies may still show deprecated APIs.

## Preferred implementation order

For frontend customization, choose the least fragile supported extension surface that satisfies the requirement:

1. Existing public/core component or supported API.
2. Plugin Outlet / wrapper outlet where intended.
3. Transformer hook for supported client value/behavior customization.
4. JS Plugin API via `apiInitializer`.
5. `modifyClass` only when no stable hook works and with regression tests.
6. Core template override only as a last resort; overrides are explicitly discouraged because they are upgrade-fragile.

For backend business actions, keep controllers thin and prefer Discourse service objects when an action coordinates policies/contracts, lookup, transactions, or multiple side effects.

## Frontend baseline

- Use current Glimmer/Ember component conventions.
- Prefer FormKit for new non-trivial forms; use its field state, validation, layout, error and test APIs instead of rebuilding the same infrastructure manually.
- Use DModal/component-based modal APIs. Controller-based modal APIs are deprecated.
- Design mobile-first. Prefer `lib/viewport` breakpoint helpers and `lib/container` container-query helpers instead of scattering hardcoded media-query widths.
- Treat touch/hover as capabilities, not as synonyms for mobile/desktop. Essential behavior must work without hover. Prefer `html.discourse-touch`, `html.discourse-no-touch`, or the Ember `capabilities` service.
- Legacy `.mobile-view`, `.desktop-view`, and `site.mobileView` layout branching should not be introduced in new code.
- Follow Discourse's modified BEM convention for new reusable CSS blocks where practical: `.block`, `.block__element`, `.block--modifier`.
- For drag/drop, resize, swipe and pointer-drag interactions, use current `discourse/ui-kit` gesture primitives. `dDraggable` is deprecated. Pointer drag/reorder must have an equivalent keyboard path and accessible outcome announcement.
- Use current Discourse type support. Where repo/skeleton configuration supports it, `.ts/.gts` are valid; JS/GJS may opt in via `/** @ts-check */`. Run `pnpm lint:types` when configured.

## Backend and data baseline

- Authorization remains server-side even if frontend controls are hidden/disabled.
- Validate mutable inputs and identifiers at the controller/service boundary.
- Do not implicitly serialize ActiveRecord models/relations. Use an explicit serializer or field allowlist.
- Use current Discourse routing conventions for plugin routes and admin endpoints.
- For multi-step business logic, prefer service objects with explicit contracts/policies/steps and clear transaction/idempotency boundaries.
- Treat authentication additions, cross-plugin contracts, payments, balances, network access, privacy/non-enumeration and migrations as high-risk boundaries requiring expanded context/review.

## Testing, linting, CI, compatibility

- Protect Ember behavior with current component/rendering tests and acceptance tests. Old `moduleForComponent` examples are historical; follow current test helpers/source.
- Current core/plugin QUnit tests are exposed at `/tests`; plugin suites can be run from Discourse with `bin/rake "plugin:qunit[plugin-name]"` or the current targeted tooling documented upstream.
- Use system specs for end-to-end browser behavior when they add confidence beyond request/QUnit tests.
- Use the official reusable Discourse GitHub Actions plugin workflow. Exact-head CI must be GREEN before a CI-gated merge; skipped/not-run checks are not evidence of success.
- Keep lint/formatting automatic and aligned with the current skeleton/config.
- Use Tachometer/current performance measurement guidance when a change claims or materially affects JS rendering/runtime performance.
- Stable/older release support is explicit. Use `.discourse-compatibility` / d-compat release-freezing strategy as appropriate instead of assuming `main` code works on older releases.

## Official reference map

### Core frontend, APIs and customization
- Ember components: https://meta.discourse.org/t/-/48891
- Ember object ownership (`getOwner`, service injection): https://meta.discourse.org/t/-/292080
- JS Plugin API: https://meta.discourse.org/t/-/41281
- Plugin Outlet connectors: https://meta.discourse.org/t/-/32727
- Transformers: https://meta.discourse.org/t/-/349954
- `modifyClass`: https://meta.discourse.org/t/-/262064
- Template overrides (discouraged): https://meta.discourse.org/t/-/247487
- AppEvents trigger reference: https://meta.discourse.org/t/-/338465
- Topic list customization: https://meta.discourse.org/t/-/350411
- Creating routes and showing data: https://meta.discourse.org/t/-/48827

### Forms, modals, layout and interaction
- FormKit: https://meta.discourse.org/t/-/326439
- DModal API: https://meta.discourse.org/t/-/268304
- Migrating old modals to DModal: https://meta.discourse.org/t/-/268057
- Designing for different devices (touch/hover): https://meta.discourse.org/t/-/367810
- Designing for responsive widths (breakpoints/viewports/containers): https://meta.discourse.org/t/-/409279
- BEM CSS guidelines: https://meta.discourse.org/t/-/361851
- Drag, resize and gesture primitives: https://meta.discourse.org/t/-/410549

### Backend and data
- Service objects: https://meta.discourse.org/t/-/333641
- Prevent accidental ActiveRecord serialization: https://meta.discourse.org/t/-/314495
- Add a managed authentication method: https://meta.discourse.org/t/-/106695
- Rails autoloading for plugins: https://meta.discourse.org/t/-/256092

### Testing, quality, performance and compatibility
- Lint/format before commits: https://meta.discourse.org/t/-/132947
- Ember acceptance/component tests: https://meta.discourse.org/t/-/49167
- Run core/plugin/theme QUnit suites: https://meta.discourse.org/t/-/66857
- End-to-end system specs: https://meta.discourse.org/t/-/325937
- GitHub Actions CI: https://meta.discourse.org/t/-/240150
- JS type hints/validation/TypeScript: https://meta.discourse.org/t/-/395136
- JS performance/Tachometer: https://meta.discourse.org/t/-/281158
- d-compat / older-release pinning: https://meta.discourse.org/t/-/272665

### Plugin fundamentals and specialized extension points
- Plugin tutorial part 1, basic plugin: https://meta.discourse.org/t/-/30515
- Plugin tutorial part 2, plugin outlet: https://meta.discourse.org/t/-/31001
- Plugin tutorial part 3, site settings: https://meta.discourse.org/t/-/31115
- Plugin tutorial part 4, Git: https://meta.discourse.org/t/-/31272
- Plugin tutorial part 5, admin interface: https://meta.discourse.org/t/-/31761
- Plugin tutorial part 6, acceptance tests: https://meta.discourse.org/t/-/32619
- Plugin tutorial part 7, publishing: https://meta.discourse.org/t/-/101636
- Add a locale from a plugin: https://meta.discourse.org/t/-/78962
- Markdown extensions: https://meta.discourse.org/t/-/66023
- Repackage a markdown-it extension: https://meta.discourse.org/t/-/84614
- Add a discourse-chat-integration provider: https://meta.discourse.org/t/-/68156

## Usage rule for agents

Do not read every reference for every task. Start with the nearest `AGENTS.md`, then consult only the relevant section/link here when the task touches that API or when current source and local conventions are ambiguous. When making a platform-level change, verify the relevant API against current Discourse source/skeleton before implementation.
