import { click, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import UserCosmeticsAdminPage from "discourse/plugins/discourse-user-cosmetics/discourse/admin/components/user-cosmetics-admin-page";

module("Component | UserCosmeticsAdminPage", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.model = {
      groups: [],
      items: [
        {
          id: 1,
          kind: "avatar_frame",
          name: "Gold Frame",
          description: "",
          image_url: "/images/gold-frame.png",
          gradient_from: null,
          gradient_to: null,
          layers: [],
          group_names: [],
          group_ids: [],
          owner_count: 3,
          enabled: true,
          is_default: true,
        },
        {
          id: 2,
          kind: "profile_effect",
          name: "Profile Aura",
          description: "",
          image_url: null,
          gradient_from: null,
          gradient_to: null,
          layers: [],
          group_names: ["staff"],
          group_ids: [],
          owner_count: 1,
          enabled: true,
          is_default: false,
        },
      ],
    };
  });

  test("uses native admin navigation and switches catalog kinds", async function (assert) {
    await render(
      <template><UserCosmeticsAdminPage @model={{this.model}} /></template>
    );

    assert.dom(".admin-controls .nav.nav-pills").exists();
    assert.dom(".duc-admin-kind-nav > li > button").exists({ count: 4 });
    assert.dom(".duc-admin-kind-nav > li > button.active").hasText("Avatar Frames");
    assert.dom(".duc-admin-table tbody tr").exists({ count: 1 });
    assert.dom(".duc-admin-table tbody tr").includesText("Gold Frame");
    assert.dom(".duc-admin-table tbody td[data-label]").exists({ count: 6 });

    await click(".duc-admin-kind-nav > li:nth-child(4) > button");

    assert.dom(".duc-admin-kind-nav > li > button.active").hasText("Profile Effects");
    assert.dom(".duc-admin-table tbody tr").exists({ count: 1 });
    assert.dom(".duc-admin-table tbody tr").includesText("Profile Aura");
    assert.dom(".duc-admin-table tbody tr").doesNotIncludeText("Gold Frame");
  });
});
