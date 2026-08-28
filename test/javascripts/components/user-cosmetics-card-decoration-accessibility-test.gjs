import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import UserCosmeticsCardDecoration from "discourse/plugins/discourse-user-cosmetics/discourse/components/user-cosmetics-card-decoration";

module("Component | UserCosmeticsCardDecoration | accessibility", function (hooks) {
  setupRenderingTest(hooks);

  let originalMatchMedia;

  hooks.beforeEach(function () {
    originalMatchMedia = globalThis.matchMedia;
  });

  hooks.afterEach(function () {
    globalThis.matchMedia = originalMatchMedia;
  });

  test("does not mount image decoration playback when reduced motion is requested", async function (assert) {
    globalThis.matchMedia = () => ({ matches: true });
    this.user = {
      cosmetics: {
        card_decoration: {
          name: "Animated decoration",
          image_url: "/uploads/animated.gif",
        },
      },
    };

    await render(
      <template>
        <div id="user-card">
          <UserCosmeticsCardDecoration @model={{this.user}} />
        </div>
      </template>
    );

    assert.dom(".duc-card-decoration-anchor").doesNotExist();
    assert.dom(".duc-card-decoration-overlay").doesNotExist();
  });

  test("keeps a static gradient decoration available under reduced motion", async function (assert) {
    globalThis.matchMedia = () => ({ matches: true });
    this.user = {
      cosmetics: {
        card_decoration: {
          name: "Static decoration",
          gradient_from: "#111111",
          gradient_to: "#333333",
        },
      },
    };

    await render(
      <template>
        <div id="user-card">
          <UserCosmeticsCardDecoration @model={{this.user}} />
        </div>
      </template>
    );

    assert.dom(".duc-card-banner").exists();
    assert.dom(".duc-card-banner-label").hasText("Static decoration");
  });
});
