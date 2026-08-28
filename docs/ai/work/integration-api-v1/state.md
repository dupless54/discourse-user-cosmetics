# Integration API v1 state

Goal: provide the stable Store -> User Cosmetics server-side contract without reversing the dependency direction.

Current base: `main@12dfdf3d6210175a27e5a71b6fdce01e9c623165`.

Scope: batch entitlement providers; direct ownership reads/grant/revoke; entitlement reads; equip/unequip; provider-aware selection cleanup; regression tests.

Out of scope: schema/migrations, payment/refund semantics, Store catalog schema, frontend changes, release/merge.

Security: base remains authoritative; provider output is validated; explicit provider denial wins; invalid provider output fails closed with an exception.
