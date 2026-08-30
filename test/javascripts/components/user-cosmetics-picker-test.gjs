import { click, render, triggerKeyEvent } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import UserCosmeticsPicker from "discourse/plugins/discourse-user-cosmetics/discourse/components/user-cosmetics-picker";
import { FRAMES_CSS_LINK_ID } from "discourse/plugins/discourse-user-cosmetics/discourse/lib/duc-current-user-presentation";

const emptyKinds = {
  nameplate: [],
  card_decoration: [],
  profile_effect: [],
};

module("Component | UserCosmeticsPicker", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.siteSettings.discourse_user_cosmetics_enabled = true;
    this.siteSettings.discourse_user_cosmetics_avatar_frames_enabled = true;
    this.siteSettings.discourse_user_cosmetics_nameplates_enabled = true;
    this.siteSettings.discourse_user_cosmetics_card_decorations_enabled = true;
    this.siteSettings.discourse_user_cosmetics_profile_effects_enabled = true;
    this.siteSettings.discourse_user_cosmetics_frame_overhang_percent = 14;
    this.selectResponse = { success: "OK" };

    pretender.get("/user-cosmetics/mine.json", () =>
      response({
        items: {
          avatar_frame: [
            {
              id: 1,
              kind: "avatar_frame",
              name: "Gold Frame",
              description: "Owned cosmetic",
              image_url: "/images/gold-frame.png",
              rarity_label: "Rare",
              rarity_color: "#b45309",
              owned: true,
              group_names: [],
            },
            {
              id: 2,
              kind: "avatar_frame",
              name: "Staff Frame",
              description: "Restricted cosmetic",
              image_url: "/images/staff-frame.png",
              owned: false,
              group_names: ["staff"],
            },
          ],
          ...emptyKinds,
        },
        active: {
          avatar_frame: 1,
          nameplate: null,
          card_decoration: null,
          profile_effect: null,
        },
      })
    );

    pretender.put("/user-cosmetics/select.json", () =>
      response(this.selectResponse)
    );
  });

  test("renders native cosmetic tabs and ownership state", async function (assert) {
    await render(<template><UserCosmeticsPicker /></template>);

    assert.dom(".duc-cosmetics-page").exists();
    assert.dom(".duc-cosmetics-tabs").hasAttribute("role", "tablist");
    assert.dom(".duc-cosmetics-tab").exists({ count: 4 });
    assert.dom(".duc-cosmetics-tab.active").exists({ count: 1 });
    assert
      .dom(".duc-cosmetics-tab.active")
      .hasAttribute("aria-selected", "true")
      .hasAttribute("tabindex", "0")
      .hasAttribute("aria-controls", "duc-cosmetics-panel");
    assert
      .dom("#duc-cosmetics-panel")
      .hasAttribute("role", "tabpanel")
      .hasAttribute("aria-labelledby", "duc-cosmetics-tab-avatar_frame");
    assert.dom(".duc-cosmetics-item").exists({ count: 2 });
    assert.dom(".duc-cosmetics-item.active").exists({ count: 1 });
    assert.dom(".duc-cosmetics-item.locked").exists({ count: 1 });
    assert.dom(".duc-cosmetics-item__lock .d-icon-lock").exists();
  });

  test("supports keyboard navigation across cosmetic tabs", async function (assert) {
    await render(<template><UserCosmeticsPicker /></template>);

    await triggerKeyEvent(
      "#duc-cosmetics-tab-avatar_frame",
      "keydown",
      "ArrowRight"
    );

    assert.dom("#duc-cosmetics-tab-nameplate").hasClass("active").isFocused();
    assert.dom("#duc-cosmetics-tab-nameplate").hasAttribute("tabindex", "0");
    assert
      .dom("#duc-cosmetics-panel")
      .hasAttribute("aria-labelledby", "duc-cosmetics-tab-nameplate");

    await triggerKeyEvent("#duc-cosmetics-tab-nameplate", "keydown", "End");

    assert.dom("#duc-cosmetics-tab-profile_effect").hasClass("active").isFocused();
  });

  test("switches cosmetic categories without opening a custom modal", async function (assert) {
    await render(<template><UserCosmeticsPicker /></template>);

    await click(".duc-cosmetics-tab:nth-child(2)");

    assert
      .dom(".duc-cosmetics-page")
      .exists("picker stays embedded in the preferences page");
    assert.dom(".duc-picker-overlay").doesNotExist();
    assert.dom(".duc-cosmetics-tab:nth-child(2)").hasClass("active");
    assert.dom(".duc-cosmetics-empty").exists();
  });

  test("hides cosmetic kinds disabled by site settings", async function (assert) {
    this.siteSettings.discourse_user_cosmetics_nameplates_enabled = false;
    this.siteSettings.discourse_user_cosmetics_card_decorations_enabled = false;
    this.siteSettings.discourse_user_cosmetics_profile_effects_enabled = false;

    await render(<template><UserCosmeticsPicker /></template>);

    assert.dom(".duc-cosmetics-tab").exists({ count: 1 });
    assert.dom(".duc-cosmetics-tab").hasText("Avatar Frames");
    assert.dom(".duc-cosmetics-item").exists({ count: 2 });
  });

  test("updates reactive current-user cosmetics and shared CSS after unequip", async function (assert) {
    const cosmetics = {
      avatar_frame: {
        id: 1,
        slug: "gold-frame",
        name: "Gold Frame",
        image_url: "/images/gold-frame.png",
      },
      nameplate: null,
      card_decoration: null,
      profile_effect: null,
    };

    this.currentUser.set("cosmetics", cosmetics);
    this.selectResponse = {
      success: "OK",
      cosmetics: {
        avatar_frame: null,
        nameplate: null,
        card_decoration: null,
        profile_effect: null,
      },
    };

    await render(<template><UserCosmeticsPicker /></template>);

    let link = document.getElementById(FRAMES_CSS_LINK_ID);
    const createdLink = !link;
    if (!link) {
      link = document.createElement("link");
      link.id = FRAMES_CSS_LINK_ID;
      link.rel = "stylesheet";
      link.href = "/user-cosmetics/frames.css";
      document.head.appendChild(link);
    }
    const originalHref = link.href;

    await click(".duc-cosmetics-section-heading .btn");

    assert.strictEqual(
      this.currentUser.cosmetics.avatar_frame,
      null,
      "the reactive current-user model receives the server response"
    );
    assert.notStrictEqual(
      link.href,
      originalHref,
      "the shared frames/nameplates stylesheet is refreshed"
    );
    assert.dom("style#discourse-user-cosmetics-current-user-style").doesNotExist();

    if (createdLink) {
      link.remove();
    } else {
      link.href = originalHref;
    }
  });
});
