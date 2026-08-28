# Current state

Last verified `main` baseline: `9edde9bebceb8a1c5f5312ff4fa7f444e2042907` (`FIX: persist cosmetic uploads with Discourse upload references (#9)`).

The work below is an **unmerged stacked PR chain**. Do not assume it exists on `main`; inspect live GitHub PR/branch state before continuing because live repository state overrides this checkpoint.

## Required release ancestry

The current release branch contains the hardening/performance chain as real Git ancestry. This was re-verified during the final release audit: PR #10 head `fc091730a131b336244d62ab88cf7c6ad6663955` and PR #24 head `0d284a9a6bd5fde28fa7b414984e430048dfbf9a` are ancestors of the current audit branch, and PR #25 still targets PR #24's branch.

Last-known exact GREEN heads for the prerequisite chain:

- PR #10 `fix/critical-integrity-hardening` — `fc091730a131b336244d62ab88cf7c6ad6663955`
- PR #11 `fix/profile-effect-layer-validation` — `ac734acdfe155c326a098fd758470410893c95ee`
- PR #12 `fix/cosmetics-stylesheet-cache-invalidation` — `c5b397ce2dfc221bcad9d9fbefc63ef48640f932`
- PR #13 `fix/user-catalog-active-entitlement` — `1443f9b05bff201dfaf23e6b21296f79dd8753ef`
- PR #14 `fix/deleted-group-item-group-cleanup` — `25a23671baba3623865d0521bb85799d9b11f0b0`
- PR #15 `fix/deleted-user-cosmetic-reference-cleanup` — `afe3b5609c512bd3abc385d84de8743a436586c0`
- PR #16 `fix/private-stylesheet-access` — `af228c08fac6e41d8aefed0e9094ae0ad7a61512`
- PR #17 `fix/username-stylesheet-invalidation` — `4f6e93061e65de7bb910377d8c1462fe6a8efd26`
- PR #18 `perf/bulk-cosmetics-css-entitlements` — `dc5ba1992aa29cb157cab04caf55fb4d596f4b15`
- PR #19 `perf/target-user-selection-cache` — `4b89a3f02603f2726b79441f183a90c39f0e23ce`
- PR #20 `perf/target-direct-grant-cache` — `946688932061679076a6fc936d28a192d5860dde`
- PR #21 `perf/bulk-mine-entitlements` — `88952f5c3188edc29780630b1f521f5656efa84b`
- PR #22 `perf/bulk-presenter-entitlements` — `156a30169212bfe05b723e05baa4f4d7d858f4e8`
- PR #23 `perf/admin-catalog-serialization` — `bbea9cb95c0e7f9b226f1faceb84f6e40f34a46a`
- PR #24 `perf/bulk-invalid-selection-cleanup` — `0d284a9a6bd5fde28fa7b414984e430048dfbf9a`

These PR descriptions record exact-head GREEN validation for their frozen candidates. Re-fetch every live head and rerun validation after any retarget/rebase/head change during an authorized merge sequence.

## Native UI / release-polish continuation

- PR #25 / `test/frontend-preferences-outlet`
  - base: PR #24 branch
  - current head: `5bac542f9aedd6f9b5dbbb2053c0ce28825ac861`
  - frontend compatibility checkpoint; official and pinned validation were GREEN on this head.
- PR #26 / `feat/native-cosmetics-preferences-v2`
  - base: PR #25 branch
  - exact head: `d0d1fe6eab9b95db06dda3b647892fc6ce6dae81`
  - replaces the legacy custom preferences/modal entry with native **Preferences → Cosmetics** navigation and route.
  - official and pinned validation were GREEN.
- PR #27 / `ux/live-cosmetics-selection-refresh`
  - base: PR #26 branch
  - exact head: `0ee13f208e97242ab091b93722091c149237db1f`
  - applies equip/unequip presentation changes without page reload and refreshes shared frame/nameplate presentation state.
  - official and pinned validation were GREEN.
- PR #28 / `cleanup/remove-legacy-cosmetics-modal`
  - base: PR #27 branch
  - exact head: `be7fc4142247d5b45349481f9a3e995dc9e0fdd6`
  - removes retired modal/preferences-entry code.
  - official and pinned validation were GREEN.
- PR #29 / `docs/native-preferences-release-readiness`
  - base: PR #28 branch
  - exact head: `80dfdea6c6c5b1a0adef87f3d60c657cb0bd15fc`
  - aligns README/release notes with the native Preferences flow.
  - official and pinned validation were GREEN.
- PR #30 / `i18n/native-cosmetics-copy-cleanup`
  - base: PR #29 branch
  - exact head: `8ee079be7016961c752eb0d6deb6308d211b57de`
  - removes retired modal copy and refreshes English/Turkish admin copy.
  - official and pinned validation were GREEN.
- PR #32 / `ux/native-responsive-cosmetics-admin`
  - base: PR #30 branch
  - exact head: `92fa79c9649d998cea0a8841b12fb70357fbf6a2`
  - makes the admin page more native/responsive and adds focused admin QUnit coverage.
  - official and pinned validation were GREEN.
- PR #33 / `audit/final-release-readiness`
  - base: PR #32 branch
  - final release consistency audit: docs/locales/plugin metadata/checkpoint only.
  - exact-head official and pinned validation must be GREEN before this becomes the final frozen checkpoint.

## Open PRs outside the current release ancestry

- PR #7 is the older native-preferences implementation and is functionally superseded by the current PR #26 path. It is not in the current release ancestry. Do not close it without explicit cleanup authorization.
- PR #31 (`ux/native-cosmetics-admin-catalog`) is a parallel admin UX candidate branched from PR #30. Its head `75fa0aeb6304d89a0258f8ead1bf9a59b5621c51` **diverges** from the current PR #32 → PR #33 release ancestry at PR #30, and its official CI run was cancelled. It must not be merged into the current chain unless explicitly reconsidered. Do not close it without explicit cleanup authorization.

## Final audit scope

The active `audit/final-release-readiness` branch is based on PR #32's exact GREEN head `92fa79c9649d998cea0a8841b12fb70357fbf6a2`.

Current audit work:
- aligns public documentation with the actual five profile-effect anchors (`top`, `bottom`, `left`, `right`, `full`) and two stack orders (`front`, `back`), for up to 10 unique layer slots;
- aligns English/Turkish admin help with that model;
- keeps plugin metadata/release notes consistent with all four cosmetic kinds;
- records the complete required release ancestry, including PR #10 → PR #24;
- runs exact-head official Discourse Plugin CI plus the pinned Critical Integrity Runtime Test before freezing the branch.

No version tag, GitHub Release, deployment, PR closure, or merge is authorized by this checkpoint.

## Product boundaries

- The base plugin owns cosmetic catalog, ownership/grants, selection, presentation, cache invalidation, and server-authoritative entitlement checks.
- Frontend site settings may hide disabled cosmetic categories, but ownership/eligibility decisions remain server authoritative.
- `discourse-user-cosmetics-store` should remain a consumer of the base plugin contract unless an explicit redesign is requested.
- Prefer native/current Discourse routes, components, theme variables, and responsive patterns over custom application shells or modal replacements.

## Authorized-release procedure

Before any merge, re-fetch every open PR/head/base and rebuild the ancestry from live GitHub state. Exclude non-ancestry PRs (#7 and #31) unless the user explicitly changes direction. Merge the required dependency chain bottom-up starting at PR #10. After every retarget/rebase/head change, rerun exact-head validation for the affected PR before merging it. After the final PR reaches `main`, run the complete official Discourse Plugin CI and pinned runtime validation on resulting `main`; only then perform version/tag/GitHub Release work if explicitly authorized.
