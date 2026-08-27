# Discourse User Cosmetics Agent Router

Canonical instructions for ChatGPT/Codex, Claude, and Gemini.

## Context routing
Current source/tests > `docs/ai/CURRENT_STATE.md` > nearest local `AGENTS.md` > stable docs > plans/history. Read only the minimum context. Always read this file, then route by touched area:
- models/controllers/admin behavior -> `app/AGENTS.md`
- presenter/CSS/seeding helpers -> `lib/AGENTS.md`
- Discourse/Glimmer/admin frontend -> `docs/ai/scopes/frontend/AGENTS.md`
- migrations/schema -> `db/AGENTS.md`
For multi-session work, use `docs/ai/work/<feature>/{state.md,progress.md,implementation-plan.md}` and read only the active slice.

## Fast task path
For non-trivial work, use `.agents/skills/task-packet/SKILL.md` before broad reads. Use `docs/ai/REPO_MAP.md` to locate code, `COMMANDS.md` only for validation, and `DECISIONS.md` only for architecture/dependency choices. Skip the formal packet for trivial one-file edits.

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

## Git and token discipline
Preserve unrelated work and `.claude/settings.local.json`. No force-push/reset/clean/branch deletion/deploy/destructive DB actions. Commit/push/PR/merge only when explicitly authorized by the current task. Prefer symbol/path-targeted reads and diffs over broad repo scans or repeated summaries.

Reusable task procedures live under `.agents/skills/`; read only the matching `SKILL.md`, including `task-packet` for non-trivial work.

## Adaptive model / effort routing
Classify execution risk with `docs/ai/EFFORT_ROUTER.md` before broad reads. Start at the lowest sufficient tier: T0 mechanical, T1 routine, T2 high-risk, T3 exceptional. Escalate for risk/ambiguity rather than task size, and de-escalate when the risky phase ends. Use platform-native workers under `.claude/agents/` or `.codex/agents/` when supported; never trade away correctness, security, or validation to save tokens.
