# Cosmetics surface regression hotfix

Goal: restore cosmetic presentation on discovery/ambient user surfaces and restore the core profile avatar after the recent native-surface refactors.

Effort: T1 bounded regression fix. CSS generation remains security-sensitive; existing URL validation/escaping and server-authoritative entitlement filtering are preserved.

Current official Discourse source verified at `discourse/discourse@24ca6775e3db18f95a047af592733ce78b3e1e07`:
- `user-profile-avatar-img-wrapper` is a wrapper PluginOutlet whose default block contains the core huge avatar;
- `api.renderInOutlet` replaces wrapper-outlet default content, while `renderAfterWrapperOutlet` preserves it;
- desktop topic-list poster avatars use `DUserLink`, and mobile topic-list avatars do the same;
- `DUserLink` emits `data-user-card=<username>` while native post `DUserAvatar` carries the `.main-avatar` class.

Root causes:
- Phase 6 registered the frame component with `renderInOutlet("user-profile-avatar-img-wrapper", ...)`, replacing the core profile avatar block;
- Phase 7 removed username-keyed ambient avatar-frame CSS when moving posts to `post-avatar-class`;
- Phase 11 removed username-keyed ambient nameplate CSS when moving posts/mentions to native transformers.

Fix:
- append the profile frame component with `renderAfterWrapperOutlet` so the core avatar remains rendered;
- keep stable numeric native post/mention selectors and restore a bounded `data-user-card` compatibility layer for ambient DUserLink surfaces;
- exclude `.main-avatar` from ambient frame CSS and transformed post-name descendants/mentions from ambient nameplate CSS to avoid duplicate effects;
- restore username-change stylesheet invalidation because the ambient compatibility selectors are username-keyed;
- keep entitlement filtering, query batching, profile/user-card dedicated components, current-user header component, routes, serializers, persistence, and Store integration unchanged.

Acceptance: profile avatar visible with frame; discovery/topic-list ambient frames/nameplates restored; post/mention cosmetics remain native and non-duplicated; rename rotates shared CSS; unrelated user updates do not; targeted specs and latest exact-head official Discourse Plugin CI GREEN before merge.
