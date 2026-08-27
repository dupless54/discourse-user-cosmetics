# Durable decisions

Load only when an architecture or dependency choice is relevant.

- This plugin owns cosmetic catalog, ownership, active selection, and public presentation data.
- Ownership/selection/admin grants are server-authoritative; the client never establishes entitlement.
- `discourse-user-cosmetics-store` may depend on this base plugin; this base plugin must not depend on Store without an explicit redesign.
- Public cosmetic fields contain presentation data only and must remain safe for CSS/HTML/URL rendering.
- Seeder behavior is idempotent and must not overwrite user/admin-managed state.

Do not record temporary PR/CI state here; use `CURRENT_STATE.md` for volatile facts.
