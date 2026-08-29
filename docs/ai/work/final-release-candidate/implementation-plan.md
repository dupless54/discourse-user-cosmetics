# Final User Cosmetics Release Candidate

Goal: keep the final stacked Base contract candidate and carry the one still-unique native Admin Catalog UX delta before project-wide merges.
Allowed paths: admin catalog component/test, a small admin-native stylesheet + asset registration, this task packet.
Relevant context: parent Base PR #46 exact head `8c7f0a0b5ee2c66e5f3f0c6e317f1d69ec3cef33`; native admin UX source PR #31 head `7be6f62f719b7a8736e2e4719914a51cfba2581e`; old Preferences PR #7 is already functionally superseded by newer final-stack Preferences surfaces.
Acceptance: Discourse native `admin-controls`/`nav-pills`; existing current validation/scroll behavior preserved; responsive table retained; Edit/Delete have accessible translated labels; no backend/schema/entitlement/selection/contract changes.
Validation: exact-head Official Discourse Plugin CI; then Store final runtime must pin this final Base SHA and pass migration/contract/RSpec/QUnit.
Risk: release-candidate composition/UI regression only; no persistence or public contract change.
Effort tier: T2 release integration (frontend delta itself is T1).
Escalation trigger: admin component/test conflict with current final-stack behavior or downstream Store runtime regression.
