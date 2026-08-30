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
        {
          id: 2,
          kind: "profile_effect",
          name: "Profile Aura",
          description: "",
          image_url: null,
          group_ids: [],
          group_names: ["staff"],
          owner_count: 1,
          enabled: true,
          is_default: false,
          layers: [],
        },
      ],
      groups: [],
    };
  });

  test("uses native admin navigation and responsive table metadata", async function (assert) {
    await render(
      <template><UserCosmeticsAdminPage @model={{this.model}} /></template>
    );

    assert.dom(".duc-admin-header").exists();
    assert.dom(".duc-admin-new-item").exists();
    assert.dom(".admin-controls .nav.nav-pills").exists();
    assert.dom(".duc-admin-kind-nav > li > button").exists({ count: 4 });
    assert.dom(".duc-admin-kind-nav > li > button.active").hasClass("active");
    assert.dom(".duc-admin-kind-label").hasText("Avatar Frames");
    assert.dom(".duc-admin-kind-count").exists({ count: 4 });
    assert.dom(".duc-admin-kind-count").hasText("1");
    assert.dom(".duc-admin-table tbody tr").exists({ count: 1 });
    assert.dom(".duc-admin-table tbody tr").includesText("Gold Frame");
    assert.dom(".duc-admin-item-description").hasText("Featured frame");
    assert.dom(".duc-admin-status-badge--enabled").hasText("Enabled");
    assert.dom(".duc-admin-name-cell[data-label]").exists();
    assert.dom(".duc-admin-row-actions[data-label]").exists();
    assert.dom(".duc-admin-row-action-buttons .btn").exists({ count: 2 });
  });

  test("switches categories inline and opens the native admin form", async function (assert) {
    await render(
      <template><UserCosmeticsAdminPage @model={{this.model}} /></template>
    );

    await click(".duc-admin-kind-nav > li:nth-child(4) > button");

    assert.dom(".duc-admin-kind-nav > li:nth-child(4) > button").hasClass("active");
    assert.dom(".duc-admin-table tbody tr").exists({ count: 1 });
    assert.dom(".duc-admin-table tbody tr").includesText("Profile Aura");
    assert.dom(".duc-admin-table tbody tr").doesNotIncludeText("Gold Frame");

    await click(".duc-admin-new-item");

    assert.dom(".duc-admin-form").exists();
    assert.dom(".duc-admin-page").exists("admin form remains embedded in the page");
  });
});
