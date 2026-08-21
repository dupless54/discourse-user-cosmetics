import { apiInitializer } from "discourse/lib/api";
import UserCosmeticsNameplate from "../components/user-cosmetics-nameplate";
import UserCosmeticsCardDecoration from "../components/user-cosmetics-card-decoration";
import UserCosmeticsPreferencesEntry from "../components/user-cosmetics-preferences-entry";

const FRAMES_CSS_LINK_ID = "discourse-user-cosmetics-frames-css";
const CURRENT_USER_STYLE_ID = "discourse-user-cosmetics-current-user-style";

export default apiInitializer("1.8.0", (api) => {
  // Make the `cosmetics` field we add server-side (see plugin.rb) a proper
  // tracked field on the user model, so it's reactive in the UI. Guarded
  // with a typeof check since addModelField is a newer API -- if it isn't
  // present, the field is usually still readable, just not reactive.
  if (typeof api.addModelField === "function") {
    api.addModelField("user", "cosmetics", { defaultValue: null });
  }

  // The bulk of avatar-frame rendering is done by a single, cacheable CSS
  // file generated server-side (see DiscourseUserCosmetics::CssBuilder).
  // Loading it once here means frames keep showing up correctly everywhere
  // Discourse renders an avatar, without us having to hook every individual
  // place avatars are drawn.
  if (!document.getElementById(FRAMES_CSS_LINK_ID)) {
    const link = document.createElement("link");
    link.id = FRAMES_CSS_LINK_ID;
    link.rel = "stylesheet";
    link.href = "/user-cosmetics/frames.css";
    document.head.appendChild(link);
  }

  // Small bonus: the header's own "current user" avatar toggle isn't a
  // user-card trigger (it opens the user menu, not a card), so it isn't
  // covered by the rule above. We already know who the current user is on
  // the client, so give that one spot its own tiny inline style too.
  const currentUser = api.getCurrentUser();
  const frame = currentUser?.cosmetics?.avatar_frame;

  if (frame?.image_url) {
    let styleTag = document.getElementById(CURRENT_USER_STYLE_ID);
    if (!styleTag) {
      styleTag = document.createElement("style");
      styleTag.id = CURRENT_USER_STYLE_ID;
      document.head.appendChild(styleTag);
    }

    const safeUrl = frame.image_url.replace(/"/g, '\\"');
    styleTag.textContent = `
      #current-user .avatar,
      .header-dropdown-toggle.current-user .avatar {
        position: relative;
      }
      #current-user .avatar::after,
      .header-dropdown-toggle.current-user .avatar::after {
        content: "";
        position: absolute;
        inset: -14%;
        background-image: url("${safeUrl}");
        background-size: contain;
        background-repeat: no-repeat;
        background-position: center;
        pointer-events: none;
        z-index: 2;
      }
    `;
  }

  // Nameplates + card decorations render into a handful of core outlets.
  // Wrapped defensively so that if a particular outlet name ever changes in
  // a future Discourse release, the rest of the plugin (most importantly
  // the CSS above) keeps working regardless.
  if (typeof api.renderInOutlet === "function") {
    api.renderInOutlet("user-card-post-names", UserCosmeticsNameplate);
    api.renderInOutlet("user-profile-primary", UserCosmeticsNameplate);
    api.renderInOutlet("user-card-metadata", UserCosmeticsCardDecoration);
    api.renderInOutlet("user-custom-preferences", UserCosmeticsPreferencesEntry);
  }
});
