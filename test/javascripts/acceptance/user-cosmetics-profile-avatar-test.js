import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

acceptance("User Cosmetics | Profile avatar wrapper", function (needs) {
  needs.user();

  test("preserves the core profile avatar while cosmetics outlets are registered", async function (assert) {
    await visit("/u/eviltrout");

    assert
      .dom(".user-profile-avatar img.avatar")
      .exists("the core profile avatar is not replaced by the cosmetics frame outlet");
  });
});
