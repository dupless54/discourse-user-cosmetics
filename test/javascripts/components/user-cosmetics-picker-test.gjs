import { click, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import UserCosmeticsPicker from "discourse/plugins/discourse-user-cosmetics/discourse/components/user-cosmetics-picker";

const emptyKinds = {
  nameplate: [],
  card_decoration: [],
  profile_effect: [],
};

module("Component | UserCosmeticsPicker", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    pretender.get("/user-cosmetics/mine.json", () =>
      response({
        items: {
          avatar_frame: [
            {
              id: 1,
              kind: "avatar_frame",
              name: "Gold Frame",
              description: "Owned cosmetic",
              image_url: "/images/gold-frame.png",
              rarity_label: "Rare",
              rarity_color: "#b45309",
              owned: true,
              group_names: [],
            },
            {
              id: 2,
              kind: "avatar_frame",
              name: "Staff Frame",
              description: "Restricted cosmetic",
              image_url: "/images/staff-frame.png",
              owned: false,
              group_names: ["staff"],
            },
          ],
          ...emptyKinds,
        },
        active: {
          avatar_frame: 1,
          nameplate: null,
          card_decoration: null,
          profile_effect: null,
        },
      })
    );

    pretender.put("/user-cosmetics/select.json", () => response({ success: "OK" }));
  });

  test("renders native cosmetic tabs and ownership state", async function (assert) {
    await render(<template><UserCosmeticsPicker /></template>);

    assert.dom(".duc-cosmetics-page").exists();
    assert.dom(".duc-cosmetics-tab").exists({ count: 4 });
    assert.dom(".duc-cosmetics-tab.active").exists({ count: 1 });
    assert.dom(".duc-cosmetics-item").exists({ count: 2 });
    assert.dom(".duc-cosmetics-item.active").exists({ count: 1 });
    assert.dom(".duc-cosmetics-item.locked").exists({ count: 1 });
    assert.dom(".duc-cosmetics-item__lock .d-icon-lock").exists();
  });

  test("switches cosmetic categories without opening a custom modal", async function (assert) {
    await render(<template><UserCosmeticsPicker /></template>);

    await click(".duc-cosmetics-tab:nth-child(2)");

    assert
      .dom(".duc-cosmetics-page")
      .exists("picker stays embedded in the preferences page");
    assert.dom(".duc-picker-overlay").doesNotExist();
    assert.dom(".duc-cosmetics-tab:nth-child(2)").hasClass("active");
    assert.dom(".duc-cosmetics-empty").exists();
  });
});
