import { apiInitializer } from "discourse/lib/api";
import UserCosmeticsNameplate from "../components/user-cosmetics-nameplate";
import UserCosmeticsCardDecoration from "../components/user-cosmetics-card-decoration";
import UserCosmeticsCardMessage from "../components/user-cosmetics-card-message";
import UserCosmeticsHeaderFrame from "../components/user-cosmetics-header-frame";
import UserCosmeticsLiveSync from "../components/user-cosmetics-live-sync";
import UserCosmeticsProfileEffect from "../components/user-cosmetics-profile-effect";
import {
  FRAMES_CSS_LINK_ID,
  refreshCosmeticsStylesheet,
} from "../lib/duc-current-user-presentation";
import {
  COSMETICS_CHANGE_CHANNEL,
  COSMETICS_CHANGE_EVENT,
  CSS_BACKED_COSMETIC_KINDS,
  cosmeticsUsername,
  fetchLatestCosmetics,
  matchesCosmeticsChange,
} from "../lib/duc-live-cosmetics";
import { installCosmeticsResumeSync } from "../lib/duc-resume-sync";

export default apiInitializer("1.8.0", (api) => {
  const siteSettings = api.container.lookup("service:site-settings");
  const appEvents = api.container.lookup("service:app-events");
  const messageBus = api.container.lookup("service:message-bus");

  // Server-generated post/nameplate presentation remains a shared stylesheet.
  if (!document.getElementById(FRAMES_CSS_LINK_ID)) {
    const link = document.createElement("link");
    link.id = FRAMES_CSS_LINK_ID;
    link.rel = "stylesheet";
    link.href = "/user-cosmetics/frames.css";
    document.head.appendChild(link);
  }

  const currentUser = api.getCurrentUser();

  // Reconcile browser/PWA resume state with server truth. Header frame rendering
  // itself is reactive through the current-user model and the supported header
  // outlet below, so no global style injection is needed here.
  installCosmeticsResumeSync({
    currentUser,
    siteSettings,
    appEvents,
  });

  // Carry selections made in another tab/browser into already-open surfaces.
  messageBus.subscribe(COSMETICS_CHANGE_CHANNEL, (data) => {
    if (data?.user_id === undefined || !data?.kind) {
      return;
    }

    if (CSS_BACKED_COSMETIC_KINDS.has(data.kind)) {
      refreshCosmeticsStylesheet();
    }

    appEvents.trigger(COSMETICS_CHANGE_EVENT, data);

    if (!matchesCosmeticsChange(currentUser, data)) {
      return;
    }

    fetchLatestCosmetics(cosmeticsUsername(currentUser)).then((cosmetics) => {
      if (cosmetics === undefined || !currentUser) {
        return;
      }

      currentUser.set("cosmetics", cosmetics);
    });
  });

  if (typeof api.renderInOutlet === "function") {
    api.renderInOutlet("user-dropdown-button__after", UserCosmeticsHeaderFrame);
    api.renderInOutlet("user-card-metadata", UserCosmeticsLiveSync);
    api.renderInOutlet("user-profile-primary", UserCosmeticsLiveSync);
    api.renderInOutlet("user-card-post-names", UserCosmeticsNameplate);
    api.renderInOutlet("user-profile-primary", UserCosmeticsNameplate);
    api.renderInOutlet("user-card-metadata", UserCosmeticsCardDecoration);
    api.renderInOutlet(
      "user-card-below-message-button",
      UserCosmeticsCardMessage
    );
    api.renderInOutlet("user-card-metadata", UserCosmeticsProfileEffect);
    api.renderInOutlet("user-profile-primary", UserCosmeticsProfileEffect);
  }
});
