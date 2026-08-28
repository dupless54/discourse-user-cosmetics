import User from "discourse/models/user";

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
  const username = cosmeticsUsername(user);
  const changedUsername = String(data?.username_lower ?? "").toLowerCase();

  return Boolean(username && changedUsername && username === changedUsername);
}

export function fetchLatestCosmetics(username) {
  const key = String(username ?? "").trim().toLowerCase();
  if (!key) {
    return Promise.resolve(undefined);
  }

  const pending = pendingByUsername.get(key);
  if (pending) {
    return pending;
  }

  const request = User.findByUsername(key, { forCard: true })
    .then((user) => user?.cosmetics ?? null)
    .catch(() => undefined)
    .finally(() => pendingByUsername.delete(key));

  pendingByUsername.set(key, request);
  return request;
}
