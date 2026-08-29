import { module, test } from "qunit";
import {
  prefersReducedMotion,
  REDUCED_MOTION_QUERY,
} from "discourse/plugins/discourse-user-cosmetics/discourse/lib/duc-motion";

module("Unit | duc motion", function (hooks) {
  let originalMatchMedia;

  hooks.beforeEach(function () {
    originalMatchMedia = globalThis.matchMedia;
  });

  hooks.afterEach(function () {
    globalThis.matchMedia = originalMatchMedia;
  });

  test("detects the operating system reduced-motion preference", function (assert) {
    let requestedQuery;
    globalThis.matchMedia = (query) => {
      requestedQuery = query;
      return { matches: true };
    };

    assert.true(prefersReducedMotion());
    assert.strictEqual(requestedQuery, REDUCED_MOTION_QUERY);
  });

  test("fails open to normal motion when matchMedia is unavailable", function (assert) {
    globalThis.matchMedia = undefined;

    assert.false(prefersReducedMotion());
  });
});
