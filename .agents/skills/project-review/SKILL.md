---
name: project-review
description: Optionally perform an independent defect review when risk, ambiguity, or the user warrants a second opinion.
---
# Independent review
This skill is optional. Read the locked task, root/local rules, latest diff/source, and test/CI evidence yourself. Check scope, correctness, edge cases, auth/privacy, framework compatibility, DB/performance when relevant, and meaningful test gaps. Return concise findings, blockers, and recommended fixes; do not emit or require APPROVE/REJECT states and do not manufacture style-only blockers. Merge eligibility is defined only by the CI-only gate in root `AGENTS.md`.
