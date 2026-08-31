# Rails engine / route autoload phase 9 state

## Parent
- Base branch: `main`
- Base commit: `45b2dbcb633d73602aa4d5e0557da4b97cfafcf3`

## Source baseline
- Current official Rails autoloading guide: `discourse/discourse` `docs/developer-guides/docs/04-plugins/11-rails-autoloading.md`.
- Current official plugin skeleton: root `plugin.rb` loads `lib/<namespace>/engine.rb`; the engine isolates the namespace and `config/routes.rb` owns engine routes/mounting.
- Current Discourse core plugins such as Automation mount isolated engines at `/` while keeping full plugin URL prefixes inside the engine route table.

## Scope
- Add `DiscourseUserCosmetics::Engine` and load it from the root of `plugin.rb`.
- Move plugin-owned request routes from `plugin.rb` to `config/routes.rb` without changing URL, HTTP verb, controller action, JSON default, staff constraint, or numeric-id constraint.
- Preserve `/admin/plugins/user-cosmetics` and both `/u|users/:username/preferences/cosmetics` core-controller routes on `Discourse::Application`.
- Stop manually requiring `app/models` and `app/controllers`; let the engine autoload those paths.
- Keep `lib/discourse_user_cosmetics` explicit in this phase. `integration_contract.rb` and `showcase_integration.rb` reopen `DiscourseUserCosmetics::Integration`, so adding the whole lib directory to Zeitwerk before normalizing those files would violate filename/constant expectations.

## Acceptance
Existing request specs must continue to exercise the same public/admin endpoints, preferences route specs must remain green, staff authorization must remain unchanged, and official CI must pass Zeitwerk eager-load/reload checks on the exact PR head.

## Risk / effort
T2 because routes are plugin public contracts. Escalate and stop if route recognition, authorization, plugin boot, or public integration behavior changes rather than remaining a structural refactor.
