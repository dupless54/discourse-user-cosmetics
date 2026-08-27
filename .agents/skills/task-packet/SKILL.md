---
name: task-packet
description: Compress a non-trivial task into the minimum execution context before broader reads.
---
# Task packet

For non-trivial implementation, review, or CI repair, create this packet before broad reads:

Goal:
Allowed paths:
Relevant context:
Acceptance:
Validation:
Risk:

Rules:
- Target 12 lines or fewer, but exceed that limit whenever correctness, security, migration, public-contract, or acceptance detail would otherwise be lost.
- Resolve locations from `docs/ai/REPO_MAP.md` first; it is a navigation hint, never authority. If it is stale or conflicts with current source/tests, use targeted search and trust current source/tests.
- Read `docs/ai/DECISIONS.md` only when architecture/integration behavior is relevant.
- Read `docs/ai/COMMANDS.md` only when choosing validation commands.
- Prefer symbol/search -> targeted range -> dependency, never whole-file-first without need.
- Minimum context is adaptive, not fixed: if a change crosses schema, authorization, payment/network, public API/contract, persistence, or another subsystem boundary, load the relevant additional local `AGENTS.md`, source, contract, and tests.
- Do not copy history, long reasoning, or already-settled discussion into the packet.
- Reuse equivalent user-supplied scope/acceptance instead of restating it.
- Skip the formal packet for trivial one-file, low-risk edits.
- Absence of CI is never GREEN. When no required workflow/check exists, use targeted validation plus exact diff/scope validation and report `NO_CI`/`NOT_RUN` honestly.
- Correctness and safety outrank token savings; expand context when evidence is insufficient.
