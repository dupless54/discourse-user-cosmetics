import { set } from "@ember/object";
import { refreshCosmeticsStylesheet } from "./duc-current-user-presentation";
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

  // All mounted cosmetic components, including the header frame, react to the
  // current-user model. Updating server truth here is enough; presentation
  // cleanup belongs to each component/modifier lifecycle.
  setCosmetics(currentUser, cosmetics);

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
  appEvents,
  documentObject = document,
  windowObject = window,
  syncOnInstall = true,
}) {
  let wasHidden = documentObject.visibilityState === "hidden";
  let lastSyncAt = 0;
  let pendingSync = null;

  const refresh = ({ refreshStylesheet = true } = {}) => {
    const now = Date.now();
    if (pendingSync || now - lastSyncAt < MIN_RESUME_SYNC_INTERVAL_MS) {
      return pendingSync;
    }

    lastSyncAt = now;
    pendingSync = reconcileCurrentUserCosmetics({
      currentUser,
      appEvents,
      refreshStylesheet,
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

  // A normal bootstrap has just inserted /user-cosmetics/frames.css, whose
  // controller already performs conditional revalidation. Reconcile the user
  // payload once, but do not immediately mutate the link href and force a
  // second stylesheet request. Real browser/PWA resumes still cache-bust both
  // presentation sources through the normal refresh path above.
  if (syncOnInstall) {
    refresh({ refreshStylesheet: false });
  }

  return () => {
    documentObject.removeEventListener("visibilitychange", onVisibilityChange);
    windowObject.removeEventListener("pageshow", onPageShow);
  };
}
