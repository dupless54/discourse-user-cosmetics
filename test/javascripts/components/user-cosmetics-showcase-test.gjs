import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import UserCosmeticsShowcase from "discourse/plugins/discourse-user-cosmetics/discourse/components/user-cosmetics-showcase";

module("Component | UserCosmeticsShowcase", function (hooks) {
  setupRenderingTest(hooks);

  test("renders ordered public showcase items", async function (assert) {
    this.user = {
      cosmetics_showcase: [
        {
          id: 2,
          kind: "nameplate",
          name: "Night Plate",
          image_url: "/images/night.png",
          rarity_label: "Epic",
        },
        {
          id: 1,
          kind: "avatar_frame",
          name: "Gold Frame",
          image_url: "/images/gold.png",
        },
      ],
    };

    await render(
      <template><UserCosmeticsShowcase @model={{this.user}} /></template>
    );

    assert.dom(".duc-profile-showcase").exists();
    assert.dom(".duc-profile-showcase__item").exists({ count: 2 });
    assert
      .dom(".duc-profile-showcase__item:nth-child(1) strong")
      .hasText("Night Plate");
    assert
      .dom(".duc-profile-showcase__item:nth-child(2) strong")
      .hasText("Gold Frame");
    assert.dom(".duc-profile-showcase").includesText("Epic");
  });

  test("does not render an empty showcase", async function (assert) {
    this.user = { cosmetics_showcase: [] };

    await render(
      <template><UserCosmeticsShowcase @model={{this.user}} /></template>
    );

    assert.dom(".duc-profile-showcase").doesNotExist();
  });
});
