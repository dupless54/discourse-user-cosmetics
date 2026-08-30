import { render, settled } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import UserCosmeticsSurfaceAvatarFrame from "discourse/plugins/discourse-user-cosmetics/discourse/components/user-cosmetics-surface-avatar-frame";

module("Component | UserCosmeticsSurfaceAvatarFrame", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.siteSettings.discourse_user_cosmetics_frame_overhang_percent = 23;
    this.user = {
      cosmetics: {
        avatar_frame: {
          id: 7,
          image_url: "/images/surface-frame.png",
        },
      },
    };
    this.outletArgs = { user: this.user };
    this.showFrame = true;
  });

  test("decorates the Discourse user-card avatar host through outlet args", async function (assert) {
    await render(
      <template>
        <div class="user-card-avatar">
          <div>
            <UserCosmeticsSurfaceAvatarFrame @outletArgs={{this.outletArgs}} />
          </div>
        </div>
      </template>
    );

    const host = document.querySelector(".user-card-avatar");
    assert.dom(".user-card-avatar").hasClass("duc-surface-avatar-frame");
    assert.strictEqual(
      host.style.getPropertyValue("--duc-surface-avatar-frame-image"),
      'url("/images/surface-frame.png")'
    );
    assert.strictEqual(
      host.style.getPropertyValue("--duc-surface-avatar-frame-inset"),
      "-23%"
    );
    assert.dom(".duc-surface-avatar-frame-anchor").exists();
  });

  test("decorates the Discourse profile avatar host", async function (assert) {
    await render(
      <template>
        <div class="user-profile-avatar">
          <UserCosmeticsSurfaceAvatarFrame @outletArgs={{this.outletArgs}} />
        </div>
      </template>
    );

    assert.dom(".user-profile-avatar").hasClass("duc-surface-avatar-frame");
    assert
      .dom(".user-profile-avatar")
      .hasStyle({ "--duc-surface-avatar-frame-inset": "-23%" });
  });

  test("restores the host when the outlet component is torn down", async function (assert) {
    await render(
      <template>
        <div class="user-card-avatar">
          {{#if this.showFrame}}
            <UserCosmeticsSurfaceAvatarFrame @outletArgs={{this.outletArgs}} />
          {{/if}}
        </div>
      </template>
    );

    this.set("showFrame", false);
    await settled();

    const host = document.querySelector(".user-card-avatar");
    assert.dom(".user-card-avatar").doesNotHaveClass("duc-surface-avatar-frame");
    assert.strictEqual(
      host.style.getPropertyValue("--duc-surface-avatar-frame-image"),
      ""
    );
    assert.strictEqual(
      host.style.getPropertyValue("--duc-surface-avatar-frame-inset"),
      ""
    );
    assert.dom(".duc-surface-avatar-frame-anchor").doesNotExist();
  });

  test("clamps surface frame overhang to the supported range", async function (assert) {
    this.siteSettings.discourse_user_cosmetics_frame_overhang_percent = 200;

    await render(
      <template>
        <div class="user-profile-avatar">
          <UserCosmeticsSurfaceAvatarFrame @outletArgs={{this.outletArgs}} />
        </div>
      </template>
    );

    assert.strictEqual(
      document
        .querySelector(".user-profile-avatar")
        .style.getPropertyValue("--duc-surface-avatar-frame-inset"),
      "-60%"
    );
  });
});
