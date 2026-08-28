import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

acceptance("User Cosmetics | Native preferences route", function (needs) {
  needs.user();

  test("renders cosmetics as a native preferences page", async function (assert) {
    pretender.get("/user-cosmetics/mine.json", () =>
      response({
        items: {
          avatar_frame: [],
          nameplate: [],
          card_decoration: [],
          profile_effect: [],
        },
        active: {},
      })
    );

    await visit("/my/preferences/cosmetics");

    assert
      .dom(".user-nav__preferences-cosmetics")
      .exists("the native cosmetics preferences navigation entry renders");
    assert
      .dom(".duc-cosmetics-page")
      .exists("the cosmetics picker renders directly inside preferences");
    assert.dom(".duc-picker-overlay").doesNotExist("no custom modal is opened");
    assert.dom(".duc-preferences-entry").doesNotExist("the legacy outlet entry is removed");
  });
});
