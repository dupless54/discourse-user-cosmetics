import { apiInitializer } from "discourse/lib/api";
import UserCosmeticsNameplate from "../components/user-cosmetics-nameplate";
import UserCosmeticsCardDecoration from "../components/user-cosmetics-card-decoration";
import UserCosmeticsCardMessage from "../components/user-cosmetics-card-message";
import UserCosmeticsLiveSync from "../components/user-cosmetics-live-sync";
import UserCosmeticsProfileEffect from "../components/user-cosmetics-profile-effect";
import {
  FRAMES_CSS_LINK_ID,
  refreshCosmeticsStylesheet,
  syncCurrentUserAvatarFrame,
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

  // 1. CSS Dosyasını Ekleme
  if (!document.getElementById(FRAMES_CSS_LINK_ID)) {
    const link = document.createElement("link");
    link.id = FRAMES_CSS_LINK_ID;
    link.rel = "stylesheet";
    link.href = "/user-cosmetics/frames.css";
    document.head.appendChild(link);
  }

  // 2. Geçerli Kullanıcı (Current User) avatar çerçevesini senkronize et.
  const currentUser = api.getCurrentUser();
  syncCurrentUserAvatarFrame(
    currentUser?.cosmetics?.avatar_frame,
    siteSettings.discourse_user_cosmetics_frame_overhang_percent
  );

  // Normal sayfa açılışında server truth ile bir kez uzlaş. Aynı lifecycle
  // senkronu mobil/PWA resume ve bfcache dönüşlerinde de tekrar çalışır; böylece
  // ilk yüklemede eski browser/CDN CSS'i veya preload edilmiş kozmetik verisi
  // görünür kalmaz.
  installCosmeticsResumeSync({
    currentUser,
    siteSettings,
    appEvents,
  });

  // 3. Başka bir sekmede/tarayıcıda yapılan seçimleri açık sayfalara taşı.
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
      syncCurrentUserAvatarFrame(
        cosmetics?.avatar_frame,
        siteSettings.discourse_user_cosmetics_frame_overhang_percent
      );
    });
  });

  // 4. Outlet Bileşenlerini (Bileşenleri) Yükleme
  if (typeof api.renderInOutlet === "function") {
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
