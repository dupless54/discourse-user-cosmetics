export const FRAMES_CSS_LINK_ID = "discourse-user-cosmetics-frames-css";

// Transitional compatibility hook for the picker. Header avatar-frame
// presentation is now owned by UserCosmeticsHeaderFrame rendered through the
// current Discourse `user-dropdown-button__after` outlet, so no global <style>
// tag needs to be created or removed here.
export function syncCurrentUserAvatarFrame(_frame, _overhangPercent) {
  return false;
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
