# Native nameplate transformers — Phase 11

Goal: remove fragile username/data-user-card/`:has()` selectors from generated post/mention nameplate CSS without changing entitlement, persistence, asset, or selection semantics.

Effort: T1 routine frontend/library modernization.

Current official source verified:
- `discourse/discourse@c1e14963b9efe0725437f2f0a071d3c2cf4f8908`
- `post/meta-data/poster-name.gjs` applies the `poster-name-class` value transformer with both `post` and `user` context.
- `post-cooked-html-decorators/mentions.gjs` applies the `mentions-class` value transformer with resolved `user` context.
- Core itself registers `mentions-class` through the supported Plugin API.

Implementation:
- add `duc-nameplate-class.js` with stable numeric post-author and mention class transformers;
- register both supported transformers in the existing API initializer;
- generate CSS for `duc-nameplate-post-user-<id>` and `duc-nameplate-mention-user-<id>` instead of username selectors;
- keep user-card/profile nameplates on their existing scoped outlet/component lifecycle;
- keep shared stylesheet entitlement filtering and image/gradient rendering unchanged.

Acceptance:
- post author nameplates and cooked mentions receive stable numeric classes;
- generated nameplate CSS contains no username-specific `data-user-card`, `/u/<username>`, or `:has()` selectors;
- existing avatar-frame CSS remains unchanged;
- focused QUnit/RSpec coverage passes;
- latest exact PR head must be GREEN in the official `Discourse Plugin` workflow before merge.
