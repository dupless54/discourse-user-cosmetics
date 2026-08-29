# Integration Contract v1 — state

Status: Base implementation complete; validation pending.

Branch: `feature/cosmetics-integration-contract-v1`
Parent: Base accessibility PR #45 exact head `f31cdf124ec04e416b0aa51726bae9fd3b38eaff`.

Public additions only:
- `contract_version`
- `capabilities`
- `supports?`
- `contract_manifest`

Contract version: `1`.
Capabilities: ownership, entitlements, grants, selections, loadouts, showcase.

No existing public method, persistence model, entitlement rule, selection behavior, loadout behavior or showcase behavior is changed. Capability state is derived dynamically from public methods actually loaded.

Validation required: exact-head Official Discourse Plugin CI. Store consumer validation will follow in a stacked Store PR with pinned two-plugin runtime. Keep draft and unmerged until explicit user authorization.
