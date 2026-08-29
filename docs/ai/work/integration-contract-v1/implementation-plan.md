# Integration Contract v1 — implementation plan

1. Keep every existing `DiscourseUserCosmetics::Integration` public method backward-compatible.
2. Add a versioned public manifest with `contract_version`, `capabilities`, `supports?`, and `contract_manifest`.
3. Derive capability truth from methods actually loaded so optional/stacked extensions are never advertised prematurely.
4. Cover ownership, entitlements, grants, selections, loadouts, and showcase as named capabilities.
5. Do not remove the legacy companion-plugin compatibility fallback or change entitlement/selection/loadout/showcase semantics.
6. Validate the Base exact head with Official Discourse Plugin CI.
7. In Store, consume the manifest when available, fall back to legacy probes for older Base versions, update Health diagnostics, and prove the boundary with a pinned two-plugin runtime.
