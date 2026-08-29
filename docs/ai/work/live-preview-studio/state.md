# State

- Parent: PR #40 `feature/cosmetics-loadouts-v1` at `7e15ca7176e81194c714f50390152b4892f7669c`.
- Branch: `feature/cosmetics-live-preview-contract`.
- Scope: public Base contract only; no Store/UI/schema changes.
- Added contract: `current_selections_for(user:)`, `apply_selections!(user:, selections:)`.
- `apply_selections!` delegates to `SelectionService.replace_all!` and returns selection IDs plus `Presenter.summary_for` server truth.
- Merge: not authorized; keep draft until explicit user instruction.
