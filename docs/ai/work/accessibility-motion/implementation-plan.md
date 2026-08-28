# Implementation plan

Goal: Make Base cosmetics surfaces respect reduced-motion and preserve visible keyboard focus without changing cosmetic ownership/presentation contracts.
Allowed paths: Base client components/styles/tests and task docs only; generated CSS only if needed for motion safety.
Acceptance: reduced-motion disables plugin entrance/transform motion and hides animated profile-effect portals; keyboard focus remains visibly discernible on plugin-owned interactive controls; normal-motion visuals remain unchanged.
No schema, entitlement, selection, showcase, loadout, serializer, or Store changes.
Validation: Base QUnit/build/lint via Official Discourse Plugin CI.
Risk: T1 presentation/accessibility behavior.
Escalation: detecting animation would require persistence/schema or altering server entitlement/presentation data.
