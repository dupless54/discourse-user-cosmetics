import { i18n } from "discourse-i18n";

// Transitional compatibility alias for the remaining admin form. New and
// touched client code should import `i18n` directly from `discourse-i18n`,
// matching current Discourse core. Remove this file once the final caller is
// migrated.
export function t(key, options) {
  return i18n(key, options);
}

export default t;
