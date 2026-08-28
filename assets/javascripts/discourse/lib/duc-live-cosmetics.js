import { ajax } from "discourse/lib/ajax";

export const COSMETICS_CHANGE_CHANNEL = "/user-cosmetics/changes";
export const COSMETICS_CHANGE_EVENT = "user-cosmetics:changed";
export const CSS_BACKED_COSMETIC_KINDS = new Set([
  "avatar_frame",
  "nameplate",
]);

const pendingByUsername = new Map();

export function cosmeticsUsername(user) {
  return (user?.username_lower ?? user?.username ?? "").toLowerCase();
}

export function matchesCosmeticsChange(user, data) {
  const userId = user?.id;
  const changedUserId = data?.user_id;

  return Boolean(
    userId !== undefined &&
      userId !== null &&
      changedUserId !== undefined &&
      changedUserId !== null &&
      String(userId) === String(changedUserId)
  );
}

export function fetchLatestCosmetics(username, { fresh = false } = {}) {
  const key = String(username ?? "").trim().toLowerCase();
  if (!key) {
    return Promise.resolve(undefined);
  }

  const pendingKey = `${key}:${fresh ? "fresh" : "normal"}`;
  const pending = pendingByUsername.get(pendingKey);
  if (pending) {
    return pending;
  }

  const suffix = fresh ? `?duc_refresh=${Date.now()}` : "";
  const request = ajax(`/u/${encodeURIComponent(key)}/card.json${suffix}`)
    .then((json) => json?.user?.cosmetics ?? null)
    .catch(() => undefined)
    .finally(() => pendingByUsername.delete(pendingKey));

  pendingByUsername.set(pendingKey, request);
  return request;
}
