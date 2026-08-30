import { render, settled } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import UserCosmeticsHeaderFrame from "discourse/plugins/discourse-user-cosmetics/discourse/components/user-cosmetics-header-frame";

module("Component | UserCosmeticsHeaderFrame", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.siteSettings.discourse_user_cosmetics_frame_overhang_percent = 23;
    this.currentUser.set("cosmetics", {
      avatar_frame: {
        id: 7,
        image_url: "/images/header-frame.png",
      },
      nameplate: null,
      card_decoration: null,
      profile_effect: null,
    });
  });

  test("decorates the current Discourse user-dropdown host without a global style tag", async function (assert) {
    await render(
      <template>
        <li id="current-user" class="header-dropdown-toggle current-user">
          <button id="toggle-current-user" type="button">Avatar</button>
          <UserCosmeticsHeaderFrame />
        </li>
      </template>
    );

    const host = document.querySelector("#current-user");
    assert.dom("#current-user").hasClass("duc-current-user-frame");
    assert.strictEqual(
      host.style.getPropertyValue("--duc-current-user-frame-image"),
      'url("/images/header-frame.png")'
    );
    assert.strictEqual(
      host.style.getPropertyValue("--duc-current-user-frame-inset"),
      "-23%"
    );
    assert.dom(".duc-current-user-frame-anchor").exists();
    assert.dom("style#discourse-user-cosmetics-current-user-style").doesNotExist();
  });

  test("cleans the host when the reactive current-user frame is removed", async function (assert) {
    await render(
      <template>
        <li id="current-user" class="header-dropdown-toggle current-user">
          <UserCosmeticsHeaderFrame />
        </li>
      </template>
    );

    this.currentUser.set("cosmetics", {
      avatar_frame: null,
      nameplate: null,
      card_decoration: null,
      profile_effect: null,
    });
    await settled();

    const host = document.querySelector("#current-user");
    assert.dom("#current-user").doesNotHaveClass("duc-current-user-frame");
    assert.strictEqual(
      host.style.getPropertyValue("--duc-current-user-frame-image"),
      ""
    );
    assert.strictEqual(
      host.style.getPropertyValue("--duc-current-user-frame-inset"),
      ""
    );
    assert.dom(".duc-current-user-frame-anchor").doesNotExist();
  });

  test("clamps the frame overhang to the supported range", async function (assert) {
    this.siteSettings.discourse_user_cosmetics_frame_overhang_percent = 200;

    await render(
      <template>
        <li id="current-user" class="header-dropdown-toggle current-user">
          <UserCosmeticsHeaderFrame />
        </li>
      </template>
    );

    assert.strictEqual(
      document
        .querySelector("#current-user")
        .style.getPropertyValue("--duc-current-user-frame-inset"),
      "-60%"
    );
  });
});
