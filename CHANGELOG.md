# Changelog

All notable changes to `discourse-user-cosmetics` are documented here.

The current roadmap has been merged to `main`, but its release version/tag has not been assigned yet. Until that release decision is made, the completed work remains under **Unreleased**.

## Unreleased

### Added

- Public Integration API for ownership, batched entitlements, grants, and cosmetic selection operations.
- Atomic four-slot cosmetic selection contract for Store/live-preview consumers.
- Saved cosmetic loadouts with create, rename, delete, list, and atomic apply operations.
- Native profile cosmetic showcase with an ordered, entitlement-validated public presentation contract.
- Versioned Integration Contract v1 manifest with capability discovery for ownership, entitlements, grants, selections, loadouts, and showcase support.
- Native admin/catalog release improvements included by the final release candidate.

### Changed

- Store-facing integrations use explicit public contracts instead of relying on Base internals.
- Cosmetic presentation respects reduced-motion preferences and exposes clearer keyboard focus states.
- Integration capabilities are derived from the public methods actually available at runtime so partially loaded or older installations are not falsely advertised as supporting a feature.

### Fixed

- Reconciled cosmetic state with server truth during bootstrap so stale selections are not retained on mobile/current-user surfaces after refresh.
- Improved stylesheet/cache reconciliation for late-mounted cosmetic surfaces.

### Compatibility

- `discourse-user-cosmetics` remains the authoritative owner of cosmetic catalog data, entitlements, grants, active selections, loadouts, and showcase state.
- Dependency direction remains one-way: `discourse-user-cosmetics-store` may consume this plugin; this plugin does not depend on the Store.
- Integration Contract major version remains `1`.
