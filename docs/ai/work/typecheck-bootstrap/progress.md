# Typecheck bootstrap progress

- [x] Confirm current `main` base
- [x] Compare current official Discourse plugin skeleton package/tsconfig conventions
- [x] Create isolated `chore/typecheck-bootstrap` branch
- [x] Add minimal package metadata, tsconfig, and npm policy
- [x] Add dedicated CI typecheck job
- [x] Run real `ember-tsc` CI and inspect the result
- [x] Confirm no runtime source fixes are required for the current `main` code
- [x] Validate implementation head with Official Discourse Plugin CI and dedicated Typecheck job
- [x] Open PR and verify changed paths remain tooling/task-packet only
- [ ] Reconfirm CI on the final exact head after this bookkeeping update

Initial validated implementation head: `55e93b74c901373edfa8f3ac8720a04c1e70270b`

Workflow run #126 (`33334508576`) completed successfully. The dedicated `Typecheck` job executed `pnpm lint:types` / `ember-tsc -b` successfully; official frontend, backend, annotations, and linting jobs also passed.
