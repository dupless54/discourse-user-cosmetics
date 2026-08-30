export const FRAMES_CSS_LINK_ID = "discourse-user-cosmetics-frames-css";

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
