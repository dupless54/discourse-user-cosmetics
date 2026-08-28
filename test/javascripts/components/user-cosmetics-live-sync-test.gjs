import EmberObject from "@ember/object";
import { render, settled } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import UserCosmeticsLiveSync from "discourse/plugins/discourse-user-cosmetics/discourse/components/user-cosmetics-live-sync";
import UserCosmeticsNameplate from "discourse/plugins/discourse-user-cosmetics/discourse/components/user-cosmetics-nameplate";
import { COSMETICS_CHANGE_EVENT } from "discourse/plugins/discourse-user-cosmetics/discourse/lib/duc-live-cosmetics";

module("Component | UserCosmeticsLiveSync", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.user = EmberObject.create({
      id: 7,
      username: "alice",
      username_lower: "alice",
      cosmetics: {
        avatar_frame: null,
        nameplate: {
          id: 1,
          name: "Old plate",
          gradient_from: "#111111",
          gradient_to: "#222222",
        },
        card_decoration: null,
        profile_effect: null,
      },
    });

    this.cardRequests = 0;
    pretender.get("/u/alice/card.json", () => {
      this.cardRequests += 1;
      return response({
        user: {
          id: 7,
          username: "alice",
          username_lower: "alice",
          cosmetics: {
            avatar_frame: null,
            nameplate: {
              id: 2,
              name: "Fresh plate",
              gradient_from: "#333333",
              gradient_to: "#444444",
            },
            card_decoration: null,
            profile_effect: null,
          },
        },
      });
    });
  });

  test("reloads the visible user's cosmetics after a live marker", async function (assert) {
    await render(
      <template>
        <UserCosmeticsLiveSync @model={{this.user}} />
        <UserCosmeticsNameplate @model={{this.user}} />
      </template>
    );

    assert.dom("style").hasTextContaining("#111111");

    this.owner.lookup("service:app-events").trigger(COSMETICS_CHANGE_EVENT, {
      user_id: 7,
      kind: "nameplate",
    });
    await settled();

    assert.strictEqual(this.cardRequests, 1, "fresh card data is requested once");
    assert.strictEqual(this.user.cosmetics.nameplate.id, 2);
    assert.dom("style").hasTextContaining("#333333");
  });

  test("ignores live markers for another user", async function (assert) {
    await render(<template><UserCosmeticsLiveSync @model={{this.user}} /></template>);

    this.owner.lookup("service:app-events").trigger(COSMETICS_CHANGE_EVENT, {
      user_id: 8,
      kind: "card_decoration",
    });
    await settled();

    assert.strictEqual(this.cardRequests, 0);
    assert.strictEqual(this.user.cosmetics.nameplate.id, 1);
  });
});
