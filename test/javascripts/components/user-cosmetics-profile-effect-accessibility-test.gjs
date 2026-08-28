import { render } from "@ember/test-helpers";
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
    document.querySelectorAll(
      ".duc-profile-effect-portal-back, .duc-profile-effect-portal-front"
    ).forEach((element) => element.remove());
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
    assert.dom(".duc-profile-effect-portal-back").doesNotExist();
    assert.dom(".duc-profile-effect-portal-front").doesNotExist();
    assert.dom(".duc-profile-effect-layer").doesNotExist();
  });
});
