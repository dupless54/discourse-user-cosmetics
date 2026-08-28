# Live Preview Studio — Base contract

Goal: expose current four-slot selection state and one atomic apply operation for companion preview UIs.
Allowed paths: `lib/discourse_user_cosmetics/integration.rb`, `spec/lib/integration_spec.rb`, this work packet.
Relevant context: Store depends on Base; Base must not depend on Store. `SelectionService.replace_all!` already validates every slot before one locked write.
Acceptance: current selection IDs are returned for all four kinds; complete preview selections apply atomically; entitlement failure leaves prior state unchanged; result returns server-authoritative cosmetics.
Validation: Official Discourse Plugin CI on exact PR head; targeted Integration RSpec must pass inside that workflow.
Risk: public cross-plugin contract / entitlement boundary.
Effort tier: T2 for contract design, T1 for bounded implementation/tests.
Escalation trigger: any need for new schema, Store dependency in Base, bypass of `SelectionService`, or weakened entitlement validation.
