# Repository map

Use this to choose paths before searching. Source code remains authoritative if the map becomes stale.

- `plugin.rb` — plugin entrypoint and serializer/custom-field registration.
- `app/` — catalog, ownership, selection, admin/controller behavior; read `app/AGENTS.md`.
- `lib/` — presenter/CSS/seeder helpers; read `lib/AGENTS.md`.
- `assets/javascripts/discourse/` — user/admin frontend; read local `AGENTS.md`.
- `db/` — migrations/schema; read `db/AGENTS.md`.
- `assets/` and `public/` — cosmetic presentation/media; inspect only exact assets needed.
- `config/` — routes/settings/locales/configuration.
- `docs/` — AI state/workflow and stable docs; do not preload wholesale.

Fast read order: root `AGENTS.md` -> task packet -> nearest local `AGENTS.md` -> exact symbol/source -> exact test. Load `DECISIONS.md`, `COMMANDS.md`, or `CURRENT_STATE.md` only when needed.
