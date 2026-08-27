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
- Keep the packet at 12 lines or fewer.
- Resolve locations from `docs/ai/REPO_MAP.md`; do not scan the repo first.
- Read `docs/ai/DECISIONS.md` only when architecture/integration behavior is relevant.
- Read `docs/ai/COMMANDS.md` only when choosing validation commands.
- Prefer symbol/search -> targeted range -> dependency, never whole-file-first without need.
- Do not copy history, long reasoning, or already-settled discussion into the packet.
- Reuse equivalent user-supplied scope/acceptance instead of restating it.
- Skip the formal packet for trivial one-file, low-risk edits.
