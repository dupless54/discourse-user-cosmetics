# Current state

Last verified `main` baseline: `9edde9bebceb8a1c5f5312ff4fa7f444e2042907` (`FIX: persist cosmetic uploads with Discourse upload references (#9)`).

The work below is an **unmerged stacked PR chain**. Do not assume it exists on `main`; inspect current GitHub PR/branch state before continuing because live repository state overrides this checkpoint.

## Verified stack

- PR #25 / `test/frontend-preferences-outlet`
  - exact head: `5bac542f9aedd6f9b5dbbb2053c0ce28825ac861`
  - security/performance/frontend-outlet checkpoint; official and pinned validation were GREEN.
- PR #26 / `feat/native-cosmetics-preferences-v2`
  - base: PR #25 branch
  - exact head: `d0d1fe6eab9b95db06dda3b647892fc6ce6dae81`
  - replaces the legacy custom preferences/modal entry with native **Preferences → Cosmetics** navigation and route.
  - uses Discourse theme variables and responsive native-looking layouts.
  - official and pinned validation were GREEN.
- PR #27 / `ux/live-cosmetics-selection-refresh`
  - base: PR #26 branch
  - exact head: `0ee13f208e97242ab091b93722091c149237db1f`
  - equip/unequip returns refreshed presentation state, updates `currentUser.cosmetics`, refreshes `frames.css`, updates the header avatar frame without reload, and respects the configured frame overhang.
  - official and pinned validation were GREEN.
- PR #28 / `cleanup/remove-legacy-cosmetics-modal`
  - base: PR #27 branch
  - exact head: `be7fc4142247d5b45349481f9a3e995dc9e0fdd6`
  - removes the unused preferences-entry component and legacy modal/picker CSS after the native Preferences migration.
  - official and pinned validation were GREEN.
- PR #29 / `docs/native-preferences-release-readiness`
  - base: PR #28 branch
  - exact head: `80dfdea6c6c5b1a0adef87f3d60c657cb0bd15fc`
  - aligns README/release notes and this checkpoint with the native Preferences flow.
  - official and pinned validation were GREEN.
- PR #30 / `i18n/native-cosmetics-copy-cleanup`
  - base: PR #29 branch
  - exact head: `8ee079be7016961c752eb0d6deb6308d211b57de`
  - removes retired modal copy and refreshes English/Turkish admin copy.
  - official and pinned validation were GREEN.
- PR #32 / `ux/native-responsive-cosmetics-admin`
  - base: PR #30 branch
  - exact head: `92fa79c9649d998cea0a8841b12fb70357fbf6a2`
  - makes the admin page more native/responsive, adds accessible tabs and mobile card rows, and adds focused admin QUnit coverage.
  - official and pinned validation were GREEN.

## Active follow-up

`audit/final-release-readiness` is based exactly on PR #32's GREEN head `92fa79c9649d998cea0a8841b12fb70357fbf6a2`.

Current scope is final release consistency only:
- align public documentation with the actual five profile-effect anchors (`top`, `bottom`, `left`, `right`, `full`) and two stack orders (`front`, `back`), for up to 10 unique layer slots;
- keep plugin metadata and release notes consistent with all four cosmetic kinds;
- keep the release checkpoint accurate;
- run exact-head official Discourse Plugin CI plus the pinned Critical Integrity Runtime Test before treating this audit branch as GREEN.

No version tag, GitHub Release, deployment, or merge is authorized by this checkpoint.

## Product boundaries

- The base plugin owns cosmetic catalog, ownership/grants, selection, presentation, cache invalidation, and server-authoritative entitlement checks.
- Frontend site settings may hide disabled cosmetic categories, but ownership/eligibility decisions remain server authoritative.
- `discourse-user-cosmetics-store` should remain a consumer of the base plugin contract unless an explicit redesign is requested.
- Prefer native/current Discourse routes, components, theme variables, and responsive patterns over custom application shells or modal replacements.

## Continuation rules

Before new work, inspect the current PR heads, bases, changed files, and exact-head CI. Do not merge any PR without explicit user instruction. When extending the current stack, branch only from the latest fully GREEN exact head and keep each new slice narrowly scoped.

For release authorization, merge the dependency chain bottom-up. After any retarget/rebase/head change, rerun exact-head validation before merging the affected PR. Finish with full validation on the resulting `main` before version/tag/release work.
