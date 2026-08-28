// A small, defensive translation helper.
//
// Discourse's client-side translation entry point has moved around between
// versions. Rather than statically importing a package/name that might not
// match the exact Discourse version this plugin is installed on (which
// would break the *entire* JS bundle at build time, not just this string),
// we reach for the long-standing `I18n` global at call time. If it isn't
// there for some reason, we fall back to the raw key so the UI still
// renders instead of crashing.
//
// Because this is a plain function, it can be used directly as a template
// helper in .gjs files: {{t "discourse_user_cosmetics.preferences.title"}}
export function t(key, options) {
  try {
    const I18n = globalThis.I18n;
    if (I18n && typeof I18n.t === "function") {
      return I18n.t(key, options);
    }
  } catch (e) {
    // fall through to the plain-key fallback below
  }

  if (options && typeof options === "object") {
    let result = key;
    Object.keys(options).forEach((k) => {
      result = String(result).replaceAll(`%{${k}}`, options[k]);
    });
    return result;
  }

  return key;
}

export default t;
