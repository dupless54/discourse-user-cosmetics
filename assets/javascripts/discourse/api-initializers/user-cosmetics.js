import { apiInitializer } from "discourse/lib/api";
import UserCosmeticsNameplate from "../components/user-cosmetics-nameplate";
import UserCosmeticsCardDecoration from "../components/user-cosmetics-card-decoration";
import UserCosmeticsPreferencesEntry from "../components/user-cosmetics-preferences-entry";
import UserCosmeticsProfileEffect from "../components/user-cosmetics-profile-effect";

const FRAMES_CSS_LINK_ID = "discourse-user-cosmetics-frames-css";
const CURRENT_USER_STYLE_ID = "discourse-user-cosmetics-current-user-style";

export default apiInitializer("1.8.0", (api) => {
  // 1. CSS Dosyasını Ekleme
  if (!document.getElementById(FRAMES_CSS_LINK_ID)) {
    const link = document.createElement("link");
    link.id = FRAMES_CSS_LINK_ID;
    link.rel = "stylesheet";
    link.href = "/user-cosmetics/frames.css";
    document.head.appendChild(link);
  }

  // 2. Geçerli Kullanıcı (Current User) için Inline CSS Ayarları
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
      /* Avatarı saran dış buton/kutuya position veriyoruz, img etiketine değil! */
      #current-user,
      .header-dropdown-toggle.current-user {
        position: relative;
      }
      /* Çerçeveyi doğrudan dış kutunun üzerine (::after) ekliyoruz */
      #current-user::after,
      .header-dropdown-toggle.current-user::after {
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

  // 3. Outlet Bileşenlerini (Bileşenleri) Yükleme
  if (typeof api.renderInOutlet === "function") {
    api.renderInOutlet("user-card-post-names", UserCosmeticsNameplate);
    api.renderInOutlet("user-profile-primary", UserCosmeticsNameplate);
    api.renderInOutlet("user-card-metadata", UserCosmeticsCardDecoration);
    api.renderInOutlet("user-custom-preferences", UserCosmeticsPreferencesEntry);
    api.renderInOutlet("user-card-metadata", UserCosmeticsProfileEffect);
    api.renderInOutlet("user-profile-primary", UserCosmeticsProfileEffect);
  }
});