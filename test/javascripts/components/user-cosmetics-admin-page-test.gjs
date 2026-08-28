import { click, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import UserCosmeticsAdminPage from "discourse/plugins/discourse-user-cosmetics/discourse/admin/components/user-cosmetics-admin-page";

module("Component | UserCosmeticsAdminPage", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.model = {
      items: [
        {
          id: 1,
          kind: "avatar_frame",
          name: "Gold Frame",
          description: "Featured frame",
          image_url: "/images/gold-frame.png",
          group_ids: [],
          group_names: [],
          owner_count: 2,
          enabled: true,
          is_default: true,
          layers: [],
        },
      ],
      groups: [],
    };
  });

  test("renders accessible tabs and responsive table metadata", async function (assert) {
    await render(
      <template><UserCosmeticsAdminPage @model={{this.model}} /></template>
    );

    assert.dom(".duc-admin-header").exists();
    assert.dom(".duc-admin-new-item").exists();
    assert.dom('.duc-admin-tabs[role="tablist"]').exists();
    assert.dom('.duc-admin-tab[role="tab"]').exists({ count: 4 });
    assert.dom('.duc-admin-tab[aria-selected="true"]').exists({ count: 1 });
    assert.dom(".duc-admin-table-wrap").exists();
    assert.dom(".duc-admin-table tbody tr").exists({ count: 1 });
    assert.dom(".duc-admin-name-cell[data-label]").exists();
    assert.dom(".duc-admin-row-actions[data-label]").exists();
  });

  test("switches categories inline and opens the native admin form", async function (assert) {
    await render(
      <template><UserCosmeticsAdminPage @model={{this.model}} /></template>
    );

    await click(".duc-admin-tab:nth-child(2)");

    assert.dom(".duc-admin-tab:nth-child(2)").hasClass("active");
    assert.dom(".duc-admin-empty").exists();

    await click(".duc-admin-new-item");

    assert.dom(".duc-admin-form").exists();
    assert.dom(".duc-admin-page").exists("admin form remains embedded in the page");
  });
});
