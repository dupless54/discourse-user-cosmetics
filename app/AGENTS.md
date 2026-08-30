# User Cosmetics backend

- Item/group/effect-layer models define catalog structure; user-item rows define ownership; user-selection defines active choices.
- Admin item CRUD/grant/revoke/owner lists are staff-only and must validate all mutable fields.
- User selection endpoints derive the user from authentication and verify ownership/eligibility server-side.
- Serializers expose presentation summaries only; avoid leaking admin/internal ownership details.
- Deleting/updating catalog entries must consider existing ownership/selection references.

## Current Discourse backend conventions
- Keep controllers thin. When an action coordinates policy, parameter validation, model lookup, transactions, or several side effects, prefer a Discourse service object with explicit steps/contracts/policies rather than adding orchestration to the controller.
- Keep authorization inside the server-side action/service path. A frontend control being hidden or disabled is never authorization.
- Never `render json:` an ActiveRecord model or relation implicitly. Use a serializer or an explicit allowlist such as `serializable_hash(only: ...)`, and expose only fields required by the public/admin contract.
- Treat routes and admin endpoints as public contracts for this plugin: use current Discourse plugin routing/controller conventions, validate identifiers and mutable inputs, and preserve non-enumeration where privacy/authorization requires it.
- Keep transaction/idempotency boundaries explicit for ownership grants, revokes, defaults, selections, and future cross-plugin operations.
- If Store integration is involved, escalate to the cross-plugin/payment boundary rules before changing contracts; this base plugin must remain independently usable.
- For upstream rationale and links, consult `docs/ai/OFFICIAL_DISCOURSE_GUIDANCE.md` only when needed.
