# Discourse User Cosmetics Agent Router

Canonical instructions for ChatGPT/Codex, Claude, and Gemini.

## Context routing
Current source/tests > `docs/ai/CURRENT_STATE.md` > nearest local `AGENTS.md` > stable docs > plans/history. Read only the minimum context. Always read this file, then route by touched area:
- models/controllers/admin behavior -> `app/AGENTS.md`
- presenter/CSS/seeding helpers -> `lib/AGENTS.md`
- Discourse/Glimmer/admin frontend -> `docs/ai/scopes/frontend/AGENTS.md`
- frontend QUnit/component/acceptance tests -> `test/AGENTS.md`
- Ruby/request/service/system specs -> `spec/AGENTS.md`
- migrations/schema -> `db/AGENTS.md`
For multi-session work, use `docs/ai/work/<feature>/{state.md,progress.md,implementation-plan.md}` and read only the active slice. Consult `docs/ai/OFFICIAL_DISCOURSE_GUIDANCE.md` only when an implementation choice depends on upstream Discourse APIs, deprecations, responsive/device behavior, forms/modals, extension hooks, typing, testing, CI, or compatibility.

## Fast task path
For non-trivial work, use `.agents/skills/task-packet/SKILL.md` before broad reads. Use `docs/ai/REPO_MAP.md` to locate code, `COMMANDS.md` only for validation, and `DECISIONS.md` only for architecture/dependency choices. Skip the formal packet for trivial one-file edits.

## Live Discourse developer source gate
Canonical live upstream index: https://meta.discourse.org/t/developer-guides-index/308036?tl=en

For Discourse-version-sensitive implementation, refactor, review, or compatibility decisions, start at that live index and open only the task-relevant official topic(s). Plugin work prioritizes **Code & Internals + Plugins**; theme work prioritizes **Code & Internals + Themes & Components / Theme Developer Tutorial**. Verify version-sensitive APIs/deprecations against current `discourse/discourse` core or the current official skeleton when needed. Current official docs/core beat remembered examples or copied snippets unless this repository deliberately targets an older validated release via `.discourse-compatibility` / d-compat. Do not preload the full index.

- Prefer supported extension surfaces in this order when practical: existing public/core component or API -> plugin outlet / transformer / JS Plugin API -> `modifyClass` only as a last resort. Do not introduce template overrides unless no supported extension point can satisfy the requirement.
- Prefer FormKit for new non-trivial forms and DModal/component-based modal APIs for dialogs. Do not introduce deprecated controller-based modal patterns.
- Build responsive UI mobile-first with Discourse viewport/container helpers where practical. Do not base layout on legacy `.mobile-view` / `.desktop-view` or `site.mobileView` unless maintaining unavoidable legacy code.
- Essential interactions must work without hover. Use Discourse touch/hover capability helpers for capability-specific enhancements.
- New component CSS should follow Discourse's modified BEM conventions where practical; do not churn stable legacy selectors only to rename them.
- Use current `ui-kit` drag/resize/gesture primitives for new gesture interactions and provide an equivalent keyboard path. Do not introduce deprecated `dDraggable`.
- For multi-step business actions with policy/validation/side effects, prefer Discourse service objects over growing controllers into orchestration layers.
- Never serialize ActiveRecord objects implicitly. Use serializers or an explicit field allowlist.
- Use current type support when the repo/skeleton is configured for it: `.ts/.gts` or `@ts-check` for JS/GJS as appropriate, and run `pnpm lint:types` when available.
- Protect behavior with targeted QUnit/component/acceptance tests and RSpec/system specs as appropriate. Official Discourse GitHub Actions CI is required evidence; `NO_CI` is never GREEN.
- Treat stable compatibility as an explicit contract. Use `.discourse-compatibility` / d-compat branching strategy when supporting older Discourse releases; do not claim compatibility that was not validated.

## Product ownership and invariants
This plugin owns the cosmetic catalog, cosmetic item/group/layer definitions, user ownership grants, active selections, presentation data, and admin management for avatar frames, nameplates, card decorations, profile effects, and related cosmetic surfaces.

- Ownership and selection are server-authoritative; client UI is never an entitlement source.
- Admin create/update/delete/grant/revoke/owners operations remain staff-authorized.
- Public serializers expose only presentation data intentionally needed by profile/card/post UI.
- Validate cosmetic identifiers/assets and avoid unsafe CSS/HTML/URL injection.
- Keep selection compatible with owned/allowed items and fail closed for invalid references.
- `discourse-user-cosmetics-store` may consume this base plugin; do not make this base plugin depend on the Store unless an explicit architecture decision requires it.
- Seeder behavior must be idempotent and must not clobber user/admin-managed data.

## Implementation, security, tests
Follow current Discourse plugin APIs/source, make the smallest maintainable change, avoid unrelated refactors and N+1 work, and keep authorization server-side. Treat upload/asset/CSS generation and admin APIs as security-sensitive. User-visible copy belongs in locale files.

Run targeted checks for changed behavior. Never claim an unrun test passed; report NOT RUN when tooling is unavailable. Stop for unresolved architecture, schema/migration, authorization/security, cross-plugin dependency, or product ambiguity.

## CI-only merge gate
Claude/Gemini/Codex reviewer or verifier approval is not required and must never block merge. Do not request or wait for AI approvals as a merge condition.

For a normal scoped PR, the merge gate is CI only:
- validate the exact changed paths still match the task;
- use only the latest exact PR head SHA;
- require the official `Discourse Plugin` CI workflow on that exact head to conclude GREEN;
- if the repository exposes any additional required Discourse-owned CI/check context, it must also be GREEN;
- a new commit invalidates all older CI evidence;
- `NO_CI`, missing, skipped, pending, cancelled, neutral, stale-head, or failed checks are not GREEN.

When the latest exact head is GREEN and no unresolved security/schema/product/architecture blocker remains, the agent is pre-authorized to merge without asking for another user confirmation. Prefer squash merge with `expected_head_sha` when supported. Never weaken tests or broaden scope just to obtain GREEN.

## Git and token discipline
Preserve unrelated work and `.claude/settings.local.json`. No force-push/reset/clean/branch deletion/deploy/destructive DB actions. Commit/push/PR updates needed to complete an authorized development task are allowed; destructive Git/production actions still require explicit authorization. Prefer symbol/path-targeted reads and diffs over broad repo scans or repeated summaries.

Reusable task procedures live under `.agents/skills/`; read only the matching `SKILL.md`, including `task-packet` for non-trivial work.

## Adaptive model / effort routing
Classify execution risk with `docs/ai/EFFORT_ROUTER.md` before broad reads. Start at the lowest sufficient tier: T0 mechanical, T1 routine, T2 high-risk, T3 exceptional. Escalate for risk/ambiguity rather than task size, and de-escalate when the risky phase ends. Use platform-native workers under `.claude/agents/` or `.codex/agents/` when supported; never trade away correctness, security, or validation to save tokens.
