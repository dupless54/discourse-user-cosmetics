import { apiInitializer } from "discourse/lib/api";
import UserCosmeticsNameplate from "../components/user-cosmetics-nameplate";
import UserCosmeticsCardDecoration from "../components/user-cosmetics-card-decoration";
import UserCosmeticsCardMessage from "../components/user-cosmetics-card-message";
import UserCosmeticsProfileEffect from "../components/user-cosmetics-profile-effect";
import {
  FRAMES_CSS_LINK_ID,
  syncCurrentUserAvatarFrame,
} from "../lib/duc-current-user-presentation";

export default apiInitializer("1.8.0", (api) => {
  const siteSettings = api.container.lookup("service:site-settings");

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

  // 3. Outlet Bileşenlerini (Bileşenleri) Yükleme
  if (typeof api.renderInOutlet === "function") {
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
