# Typecheck bootstrap implementation plan

## Goal

Add a real, isolated JavaScript/Glimmer type-check gate to `discourse-user-cosmetics` without changing runtime behavior or coupling the work to the open admin UX PR.

## Upstream reference

Use the current `discourse/discourse-plugin-skeleton` package and `tsconfig.json` conventions as the source of truth. Keep dependency versions aligned with the skeleton where applicable.

## Scope

- add the minimal package metadata required by `ember-tsc`
- add a plugin `tsconfig.json` extending `discourse/tsconfig-plugin`
- add the skeleton npm peer-install policy
- add a dedicated CI typecheck job alongside the official reusable Discourse Plugin workflow
- fix only type errors required to make the gate meaningful and green

## Non-goals

- no backend/API/schema changes
- no product behavior changes
- no broad formatting or lint migration
- no merge of PR #58 as part of this task
- no fake/no-op typecheck command

## Validation

The latest exact PR head must have both the official reusable Discourse Plugin CI and the dedicated Typecheck job green before this task is reported ready.
