# Official Discourse Developer Guidance

This file is an on-demand router to the live upstream documentation. It must not become a frozen copy of Discourse APIs.

## Canonical live index

- Developer Guides Index: https://meta.discourse.org/t/developer-guides-index/308036?tl=en

The upstream index currently routes to the official sections for Introduction, Development Environments, Code & Internals, Plugins, Themes & Components, General Guides, and the Theme Developer Tutorial.

## Freshness rule

For any Discourse-version-sensitive implementation, refactor, review, or compatibility decision:

1. Start at the live Developer Guides Index.
2. Open only the task-relevant official topic(s).
3. Verify version-sensitive APIs/deprecations against current `discourse/discourse` core source or the current official plugin/theme skeleton before coding when needed.
4. Current official docs/core beat remembered examples, old snippets, and copied local guidance.
5. A deliberate older-release contract may differ only when explicitly documented and validated, using `.discourse-compatibility` / d-compat where appropriate.

## Task routing

- Plugin work: prioritize **Code & Internals** + **Plugins**.
- Theme/theme-component work: prioritize **Code & Internals** + **Themes & Components** and the **Theme Developer Tutorial**.
- Frontend UI: open the relevant current guides for components, JS API/outlets/Transformers, FormKit, DModal, CSS/BEM, touch/hover, responsive widths/containers, gestures, typing, and performance only when the task touches them.
- Backend/data: open the relevant current guides for routes, service objects, serialization safety, authentication, autoloading, or other touched platform contracts.
- Tests/CI: open the current QUnit/component/acceptance/system-test, lint/format, GitHub Actions CI, and compatibility guides as needed.
- Environment/setup: use the Development Environments section only for setup/runtime tasks.

## Token discipline

Do not preload every guide. The index is a discovery surface, not mandatory context. Read the nearest repository `AGENTS.md`, inspect the target source/tests, then open only the official guide(s) needed to resolve the current implementation choice.
