# Avatar frame phase 6 state

## Parent
- Base branch: `main`
- Base commit: `92e339054e8157d8f079ce6229aa75e606615053`

## Official Discourse source baseline
Validated against `discourse/discourse@768a4ed1cd8e6742fe1c1340a9c4ab01318285ec`.

- `frontend/discourse/app/components/user-card-contents.gjs`
  - exposes `user-card-avatar-flair` inside `.user-card-avatar`
  - outlet args include the card `user`
- `frontend/discourse/app/components/user-profile-avatar.gjs`
  - exposes `user-profile-avatar-img-wrapper` inside `.user-profile-avatar`
  - outlet args include the profile `user`
- `frontend/discourse/app/components/post/avatar.gjs`
  - exposes the `post-avatar` outlet and a post/user context
  - post migration is deliberately deferred until the payload/cache cost is audited

## Phase scope
- Render user-card/profile avatar frames through supported Plugin API outlets.
- Apply presentation through scoped classes/CSS custom properties owned by the mounted component lifecycle.
- Remove generated `frames.css` selectors for user-card/profile avatar surfaces.
- Preserve generated post avatar-frame selectors and nameplate selectors unchanged.

## Invariants
- No entitlement, selection, serializer payload, route/API/schema, upload, grant/revoke, Store integration, or authorization behavior changes.
- Header avatar-frame presentation remains on `user-dropdown-button__after`.
- Post avatar frames remain server-generated until a dedicated serializer/performance phase.

## Gate
Do not merge a changed head unless the official Discourse Plugin workflow is GREEN for that exact head, including Typecheck, lint, frontend QUnit/build, backend RSpec/boot and annotations.
