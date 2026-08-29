<p align="center">
  <a href="https://buymeacoffee.com/erespawn">
    <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me a Coffee" width="217" height="60">
  </a>
</p>

# Discourse User Cosmetics

A native Discourse cosmetics platform for avatar frames, nameplates, user-card decorations, and layered profile effects.

The plugin owns the cosmetic catalog, user entitlements, direct grants, active selections, loadouts, presentation data, and administrator management. Companion plugins such as `discourse-user-cosmetics-store` consume its public integration contract instead of duplicating cosmetic ownership state.

## Current Features

- **Avatar frames** shown across supported avatar surfaces.
- **Nameplates** for profile and user-card identity presentation.
- **Card decorations** with image or gradient presentation.
- **Profile effects** with up to 10 optional layers: `top`, `bottom`, `left`, `right`, and `full`, each available in `front` or `back` stack order.
- Native **Preferences → Cosmetics** user experience instead of the retired custom modal flow.
- Live equip/unequip presentation refresh without requiring a full page reload.
- Server-authoritative ownership and entitlement validation.
- Group-based access, defaults, direct user grants, rarity metadata, and administrator catalog management.
- Persistent Discourse upload references for cosmetic media.
- Responsive administrator and user interfaces using Discourse theme variables.
- English and Turkish localization.

## Completed Roadmap Highlights

The current `main` branch includes the merged cosmetics roadmap work:

- **Public Integration API v1** for approved consumers.
- **Atomic cosmetic loadouts** for saving and applying complete cosmetic sets.
- **Atomic live-preview contract** for previewing selections without making the browser an entitlement authority.
- **Native profile cosmetic showcase** for presenting owned/selected cosmetics on profile surfaces.
- **Accessibility and reduced-motion support** across animated cosmetic experiences.
- **Versioned Integration Contract v1** for stable cross-plugin consumption.
- Admin/catalog release improvements, mobile hardening, cache/selection integrity work, and release consistency fixes.

See [`CHANGELOG.md`](CHANGELOG.md) for the detailed merged roadmap record.

## Profile Effects

Profile effects are built from transparent media layers around the user card. Each of the five anchors can have a front and/or back layer:

| Anchor | Purpose |
| --- | --- |
| `top` | Effect above the card |
| `bottom` | Effect below the card |
| `left` | Left-side effect |
| `right` | Right-side effect |
| `full` | Full-card effect |

The effect model also supports reference sizing, horizontal/top/bottom overflow, and side offsets. Layers are rendered as presentation media while entitlement and selection state remain server-authoritative.

## Installation

Add the plugin to your Discourse container configuration:

```yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/dupless54/discourse-user-cosmetics.git
```

Rebuild Discourse:

```bash
cd /var/discourse
./launcher rebuild app
```

After the rebuild, enable `discourse_user_cosmetics_enabled` in site settings.

## Administration

Use **Admin → Plugins → User Cosmetics** to manage the cosmetic catalog, access rules, media, grants, rarity metadata, and profile-effect layers.

The client UI never decides whether a user owns or may equip an item. Ownership, group eligibility, grants, and active selections are validated by the plugin on the server.

## Integration Contract

`discourse-user-cosmetics` is the base cosmetics system. External consumers should use the versioned public integration API/contract rather than querying internal tables or recreating entitlement rules.

The official Store companion is [`discourse-user-cosmetics-store`](https://github.com/dupless54/discourse-user-cosmetics-store). Dependency direction is **Store → User Cosmetics**.

## Development

The repository uses exact-scope, CI-first development rules. Start with [`AGENTS.md`](AGENTS.md) and use the current source/tests as the authority for implementation details.

## Support

If this project helps your community, you can support continued development through the Buy Me a Coffee banner at the top of this README.
