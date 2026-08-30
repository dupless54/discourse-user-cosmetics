1. Keep the existing admin routes, payload shape, upload endpoints, entitlement/group semantics, layer schema, and owner grant/revoke APIs unchanged.
2. Move standard cosmetic metadata and boolean fields to Discourse FormKit with POJO draft data and async submission.
3. Keep image upload, profile-effect layers, overflow geometry, group selection, and owner management as specialized controls inside the same FormKit form.
4. Replace raw browser deletion confirmation with a dedicated DModal component invoked through the modal service.
5. Align touched buttons and responsive layout code with current Discourse UI-kit and `lib/viewport` APIs without broad class-renaming churn.
6. Add focused rendering tests for FormKit fields and the DModal confirmation surface.
7. Run Official Discourse Plugin CI on the exact PR head; address only scoped failures. Do not merge until the user explicitly asks after the final CI/scope report for this task.
