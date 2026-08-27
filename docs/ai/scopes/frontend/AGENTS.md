# User Cosmetics frontend

- Follow current Discourse/Glimmer/plugin API conventions verified from source.
- Client renders and requests cosmetics but does not decide entitlement.
- Reuse plugin-owned serialized presentation data; do not infer ownership from DOM/client state.
- Keep avatar/card/profile/post decoration behavior consistent across surfaces.
- Admin components must rely on server authorization and validate failure states.
- Escape user/admin-authored text; avoid raw HTML and arbitrary style injection.
- Maintain mobile/light/dark compatibility and locale-backed visible strings.
