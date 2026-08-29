# Integration API v1 implementation plan

1. Add `DiscourseUserCosmetics::Integration` as the public companion-plugin contract.
2. Route `EntitlementResolver` through registered batch providers while preserving the legacy `Item#usable_by?` extension fallback.
3. Make direct entitlement cleanup provider-aware and use the contract for base admin grant/revoke.
4. Add contract/regression coverage and keep the existing bulk entitlement performance path unchanged when no provider is registered.
5. Validate exact head with official Discourse Plugin CI and pinned Critical Integrity Runtime Test.
6. In `discourse-user-cosmetics-store`, prefer the new contract when available, retain a compatibility fallback for older base-plugin installations, and migrate purchase/gift ownership operations to the contract.
