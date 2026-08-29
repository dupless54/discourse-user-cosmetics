# Implementation plan

Goal: Add a public, user-curated cosmetic showcase to native Discourse profiles.
Allowed paths: Base Integration/presentation/controller, user preference/profile components, styles/locales/tests, task docs.
Persistence: Base-owned user custom field containing at most 6 ordered cosmetic item IDs; no schema migration.
Authority: save and render both revalidate enabled kind + current entitlement server-side.
Acceptance: owner can select/reorder/remove up to 6 usable cosmetics; public profile shows only still-valid items; showcase is independent from equipped selections/loadouts; responsive/light/dark.
Validation: Base request/service/QUnit + Official Discourse Plugin CI; no Store dependency.
Risk: T2 public presentation + entitlement boundary.
Escalation: schema need, arbitrary profile editing, entitlement leakage, or Base→Store dependency.