import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

acceptance("User Cosmetics | Preferences outlet", function (needs) {
  needs.user();

  test("renders the cosmetics entry on the profile preferences page", async function (assert) {
    await visit("/my/preferences/profile");

    assert
      .dom(".duc-preferences-entry")
      .exists("the cosmetics preferences entry renders through the Discourse outlet");
    assert
      .dom(".duc-open-picker-btn")
      .exists("the cosmetics picker action is available");
  });
});
