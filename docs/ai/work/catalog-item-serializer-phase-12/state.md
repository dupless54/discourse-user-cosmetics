# Explicit catalog item serializer — Phase 12

Goal: move the user catalog item's JSON shape out of `ItemsController` into a current Discourse `ApplicationSerializer` without changing entitlement, query-count, route, selection, or presentation semantics.

Effort: T1 bounded backend serialization modernization.

Current official source verified:
- `discourse/discourse@24ca6775e3db18f95a047af592733ce78b3e1e07`
- the accidental-serialization guide requires serializers or explicit field allowlists for ActiveRecord output;
- current core serializers inherit `ApplicationSerializer` and may receive already-computed caller data through serializer options.

Implementation:
- add `DiscourseUserCosmetics::CatalogItemSerializer` with the exact existing user catalog fields;
- pass the precomputed `owned`/usable decision through `@options` rather than moving entitlement checks into the serializer;
- retain resolved upload URLs and profile-effect representative layer images;
- remove the controller's private `serialize_for_user` helper;
- keep catalog loading, entitlement batching, active-selection visibility, showcase lookup, and the `select` mutation path unchanged.

Acceptance:
- user catalog JSON exposes only the existing public fields;
- restricted group/internal model data is not serialized;
- profile-effect preview image behavior is unchanged;
- existing request specs continue to prove privacy, entitlement, active-selection, and constant-query-count behavior;
- focused serializer specs pass;
- latest exact PR head must be GREEN in the official `Discourse Plugin` workflow before merge.
