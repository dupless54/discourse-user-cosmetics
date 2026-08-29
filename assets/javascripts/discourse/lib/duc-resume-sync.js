import { set } from "@ember/object";
import {
  refreshCosmeticsStylesheet,
  syncCurrentUserAvatarFrame,
} from "./duc-current-user-presentation";
import {
  COSMETICS_CHANGE_EVENT,
  cosmeticsUsername,
  fetchLatestCosmetics,
} from "./duc-live-cosmetics";

const RESUME_EVENT_KIND = "resume";
const MIN_RESUME_SYNC_INTERVAL_MS = 1000;

function setCosmetics(user, cosmetics) {
  if (typeof user?.set === "function") {
    user.set("cosmetics", cosmetics);
  } else if (user) {
    set(user, "cosmetics", cosmetics);
  }
}

export async function reconcileCurrentUserCosmetics({
  currentUser,
  siteSettings,
  appEvents,
  refreshStylesheet = true,
}) {
  if (refreshStylesheet) {
    refreshCosmeticsStylesheet();
  }

  if (!currentUser) {
    return undefined;
  }

  const cosmetics = await fetchLatestCosmetics(cosmeticsUsername(currentUser), {
    fresh: true,
  });
  if (cosmetics === undefined) {
    return undefined;
  }

  setCosmetics(currentUser, cosmetics);
  syncCurrentUserAvatarFrame(
    cosmetics?.avatar_frame,
    siteSettings.discourse_user_cosmetics_frame_overhang_percent
  );

  if (currentUser.id !== undefined && currentUser.id !== null) {
    appEvents.trigger(COSMETICS_CHANGE_EVENT, {
      user_id: currentUser.id,
      kind: RESUME_EVENT_KIND,
      cosmetics,
    });
  }

  return cosmetics;
}

export function installCosmeticsResumeSync({
  currentUser,
  siteSettings,
  appEvents,
  documentObject = document,
  windowObject = window,
  syncOnInstall = true,
}) {
  let wasHidden = documentObject.visibilityState === "hidden";
  let lastSyncAt = 0;
  let pendingSync = null;

  const refresh = () => {
    const now = Date.now();
    if (pendingSync || now - lastSyncAt < MIN_RESUME_SYNC_INTERVAL_MS) {
      return pendingSync;
    }

    lastSyncAt = now;
    pendingSync = reconcileCurrentUserCosmetics({
      currentUser,
      siteSettings,
      appEvents,
    }).finally(() => {
      pendingSync = null;
    });
    return pendingSync;
  };

  const onVisibilityChange = () => {
    if (documentObject.visibilityState === "hidden") {
      wasHidden = true;
      return;
    }

    if (wasHidden) {
      wasHidden = false;
      refresh();
    }
  };

  const onPageShow = (event) => {
    if (event.persisted) {
      refresh();
    }
  };

  documentObject.addEventListener("visibilitychange", onVisibilityChange);
  windowObject.addEventListener("pageshow", onPageShow);

  // A full reload/new browser session can start from stale browser/CDN CSS and
  // stale preloaded user presentation data without ever producing a MessageBus
  // event. Reconcile once during normal bootstrap so server truth wins before a
  // tab visibility change is required to repair the page.
  if (syncOnInstall) {
    refresh();
  }

  return () => {
    documentObject.removeEventListener("visibilitychange", onVisibilityChange);
    windowObject.removeEventListener("pageshow", onPageShow);
  };
}
