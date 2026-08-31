# Full library Zeitwerk phase 10 state

## Parent
- Base branch: `main`
- Base commit: `4dd46b2970843167869495ba5b3125c3d93488bc`

## Source baseline
Current official Discourse Rails autoloading guidance and plugin skeleton add the plugin `lib/` directory to the isolated engine autoload paths when library constants follow Zeitwerk filename/constant rules.

## Scope
- Normalize `integration_contract.rb` to define `DiscourseUserCosmetics::IntegrationContract`.
- Normalize `showcase_integration.rb` to define `DiscourseUserCosmetics::ShowcaseIntegration`.
- Extend those modules onto the existing public `DiscourseUserCosmetics::Integration` class.
- Preserve the existing public `Integration::CONTRACT_VERSION` and `Integration::CONTRACT_CAPABILITY_METHODS` constants.
- Add `lib/` to `DiscourseUserCosmetics::Engine` autoload paths.
- Remove explicit library `require_relative` calls from `plugin.rb`.

## Invariants
No ownership, entitlement-provider, grant/revoke, selection, loadout, showcase, serializer, route, authorization, persistence, or companion-plugin contract semantics change. `Integration.contract_manifest`, capability methods, showcase methods, and public contract constants must remain compatible.

## Validation
Focused integration RSpec plus the full official Discourse Plugin workflow on the latest exact PR head. Zeitwerk eager-load/reload and boot checks are required GREEN evidence.

## Risk / effort
T2 because `DiscourseUserCosmetics::Integration` is a public cross-plugin contract. Stop if constant/method availability, initialization order, entitlement behavior, or companion-plugin semantics change rather than remaining a structural autoload refactor.
