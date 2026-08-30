---
name: project-final-verify
description: Optionally perform an independent final verification for high-risk, ambiguous, or explicitly requested changes.
---
# Final verification
This skill is optional. Inspect the latest exact diff/source yourself and verify scope, trust/architecture boundaries, test evidence, and unresolved ambiguity. Return concise findings and unresolved blockers; do not emit or require APPROVE/REJECT states. Merge eligibility is defined only by the latest exact-head CI-only gate in root `AGENTS.md`.
