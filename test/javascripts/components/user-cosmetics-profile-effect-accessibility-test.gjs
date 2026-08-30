import { clearRender, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import UserCosmeticsProfileEffect from "discourse/plugins/discourse-user-cosmetics/discourse/components/user-cosmetics-profile-effect";

module("Component | UserCosmeticsProfileEffect | accessibility", function (hooks) {
  setupRenderingTest(hooks);

  let originalMatchMedia;

  hooks.beforeEach(function () {
    originalMatchMedia = globalThis.matchMedia;
  });

  hooks.afterEach(function () {
    globalThis.matchMedia = originalMatchMedia;
    document
      .querySelectorAll(".duc-profile-effect-portal")
      .forEach((element) => element.remove());
  });

  test("does not mount effect layers when reduced motion is requested", async function (assert) {
    globalThis.matchMedia = () => ({ matches: true });
    this.user = {
      cosmetics: {
        profile_effect: {
          effect_inner_width: 1200,
          layers: [
            {
              image_url: "/uploads/effect.gif",
              anchor: "full",
              stack_order: "front",
            },
          ],
        },
      },
    };

    await render(
      <template>
        <div class="effect-test-host">
          <div id="user-card">
            <UserCosmeticsProfileEffect @model={{this.user}} />
          </div>
        </div>
      </template>
    );

    assert.dom(".duc-profile-effect-anchor").exists();
    assert.dom(".duc-profile-effect-portal").doesNotExist();
    assert.dom(".duc-profile-effect-layer").doesNotExist();
    assert.dom(".effect-test-host").doesNotHaveClass("duc-profile-effect-host");
    assert.dom("#user-card").doesNotHaveClass("duc-profile-effect-card");
  });

  test("scopes active effect layers to the card host and cleans them up", async function (assert) {
    globalThis.matchMedia = () => ({ matches: false });
    this.user = {
      cosmetics: {
        profile_effect: {
          effect_inner_width: 1200,
          effect_overflow_top: 40,
          effect_overflow_bottom: 20,
          effect_overflow_horizontal: 30,
          layers: [
            {
              image_url: "/uploads/back-effect.webp",
              anchor: "full",
              stack_order: "back",
            },
            {
              image_url: "/uploads/front-effect.webp",
              anchor: "top",
              stack_order: "front",
            },
          ],
        },
      },
    };

    await render(
      <template>
        <div class="effect-test-host">
          <div id="user-card">
            <UserCosmeticsProfileEffect @model={{this.user}} />
          </div>
        </div>
      </template>
    );

    const host = document.querySelector(".effect-test-host");
    const card = document.querySelector("#user-card");

    assert.dom(".effect-test-host").hasClass("duc-profile-effect-host");
    assert.dom("#user-card").hasClass("duc-profile-effect-card");
    assert.dom(".duc-profile-effect-portal--back").exists();
    assert.dom(".duc-profile-effect-portal--front").exists();
    assert.dom(".duc-profile-effect-layer").exists({ count: 2 });
    assert.strictEqual(
      document.querySelector(".duc-profile-effect-portal--back img")?.dataset
        .stackOrder,
      "back"
    );
    assert.strictEqual(
      document.querySelector(".duc-profile-effect-portal--front img")?.dataset
        .stackOrder,
      "front"
    );

    await clearRender();

    assert.false(host.classList.contains("duc-profile-effect-host"));
    assert.false(card.classList.contains("duc-profile-effect-card"));
    assert.strictEqual(host.style.position, "", "temporary position context is restored");
    assert.dom(".duc-profile-effect-portal").doesNotExist();
  });
});
