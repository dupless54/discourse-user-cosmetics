import EmberObject from "@ember/object";
import { render, settled } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import UserCosmeticsNameplate from "discourse/plugins/discourse-user-cosmetics/discourse/components/user-cosmetics-nameplate";

module("Component | UserCosmeticsNameplate", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.user = EmberObject.create({
      cosmetics: {
        nameplate: {
          id: 1,
          name: "Gradient plate",
          gradient_from: "#112233",
          gradient_to: "#445566",
        },
      },
    });
  });

  test("decorates only the current profile name target and cleans up on removal", async function (assert) {
    await render(
      <template>
        <section class="user-main">
          <div class="user-profile-names">
            <div class="user-profile-names__primary">alice</div>
          </div>
          <UserCosmeticsNameplate @model={{this.user}} />
        </section>
        <div class="user-profile-names__primary unrelated-profile-name">bob</div>
      </template>
    );

    const target = document.querySelector(
      ".user-main .user-profile-names__primary"
    );

    assert.dom(target).hasClass("duc-nameplate-target");
    assert.dom(target).hasClass("duc-nameplate-target--profile");
    assert.notStrictEqual(target.style.backgroundImage, "");
    assert.dom(".unrelated-profile-name").doesNotHaveClass("duc-nameplate-target");

    this.user.set("cosmetics", { nameplate: null });
    await settled();

    assert.dom(target).doesNotHaveClass("duc-nameplate-target");
    assert.strictEqual(target.style.backgroundImage, "");
  });

  test("decorates the active Discourse user-card name target", async function (assert) {
    this.user.set("cosmetics", {
      nameplate: {
        id: 2,
        name: "Image plate",
        image_url: "/uploads/default/original/nameplate.webp",
      },
    });

    await render(
      <template>
        <section id="user-card" class="user-card">
          <div class="names">
            <span class="name-username-wrapper">alice</span>
          </div>
          <div class="metadata">
            <UserCosmeticsNameplate @model={{this.user}} />
          </div>
        </section>
      </template>
    );

    const target = document.querySelector("#user-card .name-username-wrapper");

    assert.dom(target).hasClass("duc-nameplate-target");
    assert.dom(target).hasClass("duc-nameplate-target--card");
    assert.true(target.style.backgroundImage.includes("nameplate.webp"));
  });
});
