export const FRAMES_CSS_LINK_ID = "discourse-user-cosmetics-frames-css";
export const CURRENT_USER_STYLE_ID =
  "discourse-user-cosmetics-current-user-style";

const DEFAULT_OVERHANG_PERCENT = 14;
const MIN_OVERHANG_PERCENT = 0;
const MAX_OVERHANG_PERCENT = 60;

function normalizedOverhangPercent(value) {
  const parsed = Number.parseInt(value, 10);
  const percent = Number.isFinite(parsed) ? parsed : DEFAULT_OVERHANG_PERCENT;

  return Math.min(
    MAX_OVERHANG_PERCENT,
    Math.max(MIN_OVERHANG_PERCENT, percent)
  );
}

function escapeCssUrl(value) {
  return String(value)
    .replace(/\\/g, "\\\\")
    .replace(/"/g, '\\"')
    .replace(/[\n\r\f]/g, "");
}

export function syncCurrentUserAvatarFrame(frame, overhangPercent) {
  const existing = document.getElementById(CURRENT_USER_STYLE_ID);

  if (!frame?.image_url) {
    existing?.remove();
    return;
  }

  const styleTag = existing ?? document.createElement("style");
  if (!existing) {
    styleTag.id = CURRENT_USER_STYLE_ID;
    document.head.appendChild(styleTag);
  }

  const inset = normalizedOverhangPercent(overhangPercent);
  const safeUrl = escapeCssUrl(frame.image_url);

  styleTag.textContent = `
    #current-user,
    .header-dropdown-toggle.current-user {
      position: relative;
    }

    #current-user::after,
    .header-dropdown-toggle.current-user::after {
      content: "";
      position: absolute;
      inset: -${inset}%;
      background-image: url("${safeUrl}");
      background-size: contain;
      background-repeat: no-repeat;
      background-position: center;
      pointer-events: none;
      z-index: 2;
    }
  `;
}

export function refreshCosmeticsStylesheet() {
  const link = document.getElementById(FRAMES_CSS_LINK_ID);
  if (!link) {
    return false;
  }

  const url = new URL(link.href, window.location.href);
  url.searchParams.set("duc_refresh", Date.now().toString());
  link.href = url.toString();
  return true;
}
