# Validation commands

Run from a Discourse checkout with this repository installed under `plugins/discourse-user-cosmetics`.

## Targeted first
- One Ruby spec, only if the relevant spec exists: `LOAD_PLUGINS=1 bin/rspec plugins/discourse-user-cosmetics/spec/path/to/example_spec.rb`
- Plugin Ruby specs, only if specs exist: `bundle exec rake "plugin:spec[discourse-user-cosmetics]"`
- Plugin QUnit, only if frontend tests exist: `CI=1 bundle exec rake "plugin:qunit[discourse-user-cosmetics]"`
- After plugin migration changes: `LOAD_PLUGINS=1 bundle exec rake db:migrate`

## CI status
No `.github/workflows` directory was present on `main` when this file was created (2026-08-27). Do not report GitHub Actions as GREEN unless a workflow/check actually exists and ran for the exact head SHA.

Use the narrowest relevant check first and never invent a missing test harness.
