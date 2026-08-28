# State

- Branch: `feature/cosmetics-profile-showcase`
- Parent: Base live-preview PR branch `feature/cosmetics-live-preview-contract`.
- Persistence: `UserCustomField`, key `discourse_user_cosmetics_showcase`, max 6 ordered IDs.
- Base owns save/render authority; Store is not required.
- Save and public render both revalidate enabled kind + current entitlement.
- Native profile outlet: `user-profile-primary`.
- Preferences editor uses `/user-cosmetics/mine.json` and `PUT /user-cosmetics/showcase.json`.
- No schema migration and no changes to active selections/loadouts.
- Merge remains prohibited without explicit user authorization.
