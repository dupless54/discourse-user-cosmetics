# User Cosmetics frontend

- Follow current Discourse/Glimmer/plugin API conventions verified from source.
- Client renders and requests cosmetics but does not decide entitlement.
- Reuse plugin-owned serialized presentation data; do not infer ownership from DOM/client state.
- Keep avatar/card/profile/post decoration behavior consistent across surfaces.
- Admin components must rely on server authorization and validate failure states.
- Escape user/admin-authored text; avoid raw HTML and arbitrary style injection.
- Maintain responsive/light/dark compatibility and locale-backed visible strings.

## Current Discourse frontend conventions
- Prefer modern Glimmer components and `apiInitializer`/current JS Plugin API patterns. Do not introduce deprecated inline `text/discourse-plugin` or legacy connector-class patterns.
- For customization, prefer supported core/public components, Plugin Outlets, Transformers, and JS Plugin API hooks. Use `modifyClass` only when no stable hook can satisfy the requirement; template overrides are a last resort.
- Prefer FormKit for new non-trivial forms so field state, validation, errors, actions, layout, and test helpers follow Discourse conventions. Do not rewrite a stable simple form solely for style consistency unless the task benefits from it.
- Use DModal/component-based modal APIs for new dialogs and confirmations; do not introduce deprecated controller-based modal APIs or raw browser dialogs when a Discourse modal is appropriate.
- Design mobile-first. Prefer `@use "lib/viewport"` for viewport breakpoints and `@use "lib/container"` when a component should respond to its own available width. Avoid ad-hoc hardcoded breakpoints unless a documented component-specific constraint requires one.
- Do not use legacy `.mobile-view` / `.desktop-view` or `site.mobileView` for new layout behavior. For touch/hover differences use `html.discourse-touch`, `html.discourse-no-touch`, or the `capabilities` service. Essential actions must remain usable without hover.
- New reusable component CSS should follow Discourse's modified BEM naming (`.block`, `.block__element`, `.block--modifier`) where practical. Avoid unnecessary selector specificity and avoid renaming stable legacy classes without product value.
- For new drag/drop, resize, swipe, or pointer-drag behavior, use current `discourse/ui-kit` gesture primitives. Do not introduce deprecated `dDraggable`; pair pointer drag/reorder behavior with an equivalent keyboard path and appropriate accessibility announcements.
- Use Discourse type information when configured. Prefer `.ts/.gts` where the current plugin skeleton/build supports it, or add `/** @ts-check */` to JS/GJS files incrementally; run `pnpm lint:types` when available and do not weaken types to silence real errors.
- Cover component behavior with focused QUnit rendering tests; use acceptance tests for route-level behavior and system specs for browser workflows that need end-to-end confidence. Prefer stable semantic selectors over DOM-shape-dependent assertions.
- For upstream rationale and links, consult `docs/ai/OFFICIAL_DISCOURSE_GUIDANCE.md` only when needed.
