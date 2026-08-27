export const COSMETIC_KINDS = [
  "avatar_frame",
  "nameplate",
  "card_decoration",
  "profile_effect",
];

const SETTING_BY_KIND = {
  avatar_frame: "discourse_user_cosmetics_avatar_frames_enabled",
  nameplate: "discourse_user_cosmetics_nameplates_enabled",
  card_decoration: "discourse_user_cosmetics_card_decorations_enabled",
  profile_effect: "discourse_user_cosmetics_profile_effects_enabled",
};

export function enabledCosmeticKinds(siteSettings) {
  return COSMETIC_KINDS.filter((kind) => siteSettings[SETTING_BY_KIND[kind]]);
}

export function hasEnabledCosmetics(siteSettings) {
  return (
    siteSettings.discourse_user_cosmetics_enabled &&
    enabledCosmeticKinds(siteSettings).length > 0
  );
}
