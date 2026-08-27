# User Cosmetics backend

- Item/group/effect-layer models define catalog structure; user-item rows define ownership; user-selection defines active choices.
- Admin item CRUD/grant/revoke/owner lists are staff-only and must validate all mutable fields.
- User selection endpoints derive the user from authentication and verify ownership/eligibility server-side.
- Serializers expose presentation summaries only; avoid leaking admin/internal ownership details.
- Deleting/updating catalog entries must consider existing ownership/selection references.
