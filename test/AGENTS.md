# User Cosmetics frontend tests

- Use current Discourse QUnit helpers and the repository's existing GJS test style; do not copy obsolete `moduleForComponent`/legacy `/qunit` examples from old documentation.
- Use rendering/component tests for isolated components, acceptance tests for routes/navigation and integrated Ember behavior, and system specs when a real browser workflow provides materially stronger coverage.
- Keep tests focused on user-visible behavior, accessibility/semantic state, API outcomes, and failure handling rather than private implementation details or exact pixel layout.
- For FormKit-backed forms, use current FormKit test helpers where they make field/submit/reset assertions clearer.
- Stub network behavior through current Discourse test infrastructure/Pretender patterns as needed; test both success and meaningful failure states for admin mutations.
- Prefer stable semantic selectors/classes/data attributes over brittle DOM position selectors. Test touch/keyboard alternatives when a feature depends on hover, gestures, drag/reorder, or responsive interaction changes.
- Run the focused plugin QUnit suite for changed frontend behavior and rely on the official Discourse Plugin GitHub Actions workflow as final CI evidence. Never treat skipped/not-run tests as passing.
- Upstream references live in `docs/ai/OFFICIAL_DISCOURSE_GUIDANCE.md`; read only the testing sections when needed.
