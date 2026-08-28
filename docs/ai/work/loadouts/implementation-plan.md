# Cosmetics loadouts V1 task packet

Goal: save the current four-slot cosmetic selection as named loadouts and apply one atomically.
Allowed paths: loadout model/migration/service, selection service, Integration API, item/user cleanup, focused specs, plugin loader, this work packet.
Relevant context: Base owns catalog, ownership, active selection and persistence; Store is a consumer only.
Acceptance: create-from-current, list, rename, delete, apply; apply revalidates all saved items and changes none if any saved item is unavailable.
Acceptance: deleted catalog items are removed from saved loadout slots; deleting a user removes their loadouts.
Acceptance: companion plugins use only `DiscourseUserCosmetics::Integration`, never Base model internals.
Validation: migration/schema review, service + Integration specs, exact diff, Official Discourse Plugin CI and pinned runtime on exact head.
Risk: schema/persistence + cross-plugin public contract + atomic selection mutation.
Effort tier: T2 for schema/contract/atomic apply; T1 for bounded model/spec wiring.
Escalation trigger: unresolved migration safety, partial-apply possibility, IDOR/user scoping, entitlement ambiguity, or provider incompatibility.
