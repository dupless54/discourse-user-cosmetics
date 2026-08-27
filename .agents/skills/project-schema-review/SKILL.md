---
name: project-schema-review
description: Review migrations, indexes, constraints, and stored-data changes for correctness and production safety.
---
# Schema review
Check existing rows, null/default/backfill, uniqueness/FKs/checks, index usefulness, lock/table-scan risk, rollback/recovery, and deploy ordering. Stop for irreversible/ambiguous data decisions; never execute destructive production operations.
