import { click, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import UserCosmeticsShowcaseEditor from "discourse/plugins/discourse-user-cosmetics/discourse/components/user-cosmetics-showcase-editor";

module("Component | UserCosmeticsShowcaseEditor", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.putCalls = 0;

    pretender.get("/user-cosmetics/mine.json", () =>
      response({
        items: {
          avatar_frame: [
            {
              id: 1,
              kind: "avatar_frame",
              name: "Gold Frame",
              image_url: "/images/gold.png",
              owned: true,
            },
            {
              id: 3,
              kind: "avatar_frame",
              name: "Locked Frame",
              image_url: "/images/locked.png",
              owned: false,
            },
          ],
          nameplate: [
            {
              id: 2,
              kind: "nameplate",
              name: "Night Plate",
              image_url: "/images/night.png",
              rarity_label: "Epic",
              owned: true,
            },
          ],
          card_decoration: [],
          profile_effect: [],
        },
        active: {},
        showcase_item_ids: [2, 1],
        showcase_limit: 6,
      })
    );

    pretender.put("/user-cosmetics/showcase.json", () => {
      this.putCalls += 1;
      return response({ showcase: [] });
    });
  });

  test("renders only entitled cosmetics with accessible native controls", async function (assert) {
    await render(<template><UserCosmeticsShowcaseEditor /></template>);

    assert.dom(".duc-showcase-editor").hasAttribute("aria-busy", "false");
    assert.dom(".duc-showcase-editor__selected-item").exists({ count: 2 });
    assert
      .dom(".duc-showcase-editor__selected-item:nth-child(1) > strong")
      .hasText("Night Plate");
    assert
      .dom(".duc-showcase-editor__selected-item:nth-child(2) > strong")
      .hasText("Gold Frame");
    assert
      .dom('.duc-showcase-editor__item-actions button[aria-label="Move earlier"]')
      .exists({ count: 2 });
    assert
      .dom('.duc-showcase-editor__item-actions button[aria-label="Move later"]')
      .exists({ count: 2 });
    assert
      .dom('.duc-showcase-editor__item-actions button[aria-label="Remove from showcase"]')
      .exists({ count: 2 });
    assert.dom(".duc-showcase-editor__available-item").doesNotExist();
    assert.dom(".duc-showcase-editor").doesNotIncludeText("Locked Frame");
  });

  test("reorders, removes, re-adds, and saves the showcase", async function (assert) {
    await render(<template><UserCosmeticsShowcaseEditor /></template>);

    await click(
      ".duc-showcase-editor__selected-item:nth-child(1) .duc-showcase-editor__item-actions button:nth-child(2)"
    );

    assert
      .dom(".duc-showcase-editor__selected-item:nth-child(1) > strong")
      .hasText("Gold Frame");
    assert
      .dom(".duc-showcase-editor__selected-item:nth-child(2) > strong")
      .hasText("Night Plate");

    await click(
      ".duc-showcase-editor__selected-item:nth-child(2) .duc-showcase-editor__item-actions button:nth-child(3)"
    );

    assert.dom(".duc-showcase-editor__selected-item").exists({ count: 1 });
    assert.dom(".duc-showcase-editor__available-item").exists({ count: 1 });

    await click(".duc-showcase-editor__available-item");
    assert.dom(".duc-showcase-editor__selected-item").exists({ count: 2 });

    await click(".duc-showcase-editor__footer .btn-primary");

    assert.strictEqual(this.putCalls, 1, "the complete ordered showcase is saved once");
    assert.dom(".duc-showcase-editor__footer").includesText("Showcase is saved");
  });
});
