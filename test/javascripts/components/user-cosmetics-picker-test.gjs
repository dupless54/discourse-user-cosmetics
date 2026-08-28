import { click, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import UserCosmeticsPicker from "discourse/plugins/discourse-user-cosmetics/discourse/components/user-cosmetics-picker";
import {
  CURRENT_USER_STYLE_ID,
  FRAMES_CSS_LINK_ID,
  syncCurrentUserAvatarFrame,
} from "discourse/plugins/discourse-user-cosmetics/discourse/lib/duc-current-user-presentation";

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

  hooks.afterEach(function () {
    document.getElementById(CURRENT_USER_STYLE_ID)?.remove();
  });

  test("renders native cosmetic tabs and ownership state", async function (assert) {
    await render(<template><UserCosmeticsPicker /></template>);

    assert.dom(".duc-cosmetics-page").exists();
    assert.dom(".duc-cosmetics-tab").exists({ count: 4 });
    assert.dom(".duc-cosmetics-tab.active").exists({ count: 1 });
    assert.dom(".duc-cosmetics-item").exists({ count: 2 });
    assert.dom(".duc-cosmetics-item.active").exists({ count: 1 });
    assert.dom(".duc-cosmetics-item.locked").exists({ count: 1 });
    assert.dom(".duc-cosmetics-item__lock .d-icon-lock").exists();
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

  test("applies returned cosmetics immediately after unequip", async function (assert) {
    const frame = {
      id: 1,
      slug: "gold-frame",
      name: "Gold Frame",
      image_url: "/images/gold-frame.png",
    };
    const cosmetics = {
      avatar_frame: frame,
      nameplate: null,
      card_decoration: null,
      profile_effect: null,
    };

    this.currentUser.set("cosmetics", cosmetics);
    this.siteSettings.discourse_user_cosmetics_frame_overhang_percent = 23;
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

    syncCurrentUserAvatarFrame(frame, 23);

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
    const styleTag = document.getElementById(CURRENT_USER_STYLE_ID);

    assert.true(Boolean(styleTag), "current-user frame style is installed");
    assert.true(
      styleTag.textContent.includes("inset: -23%"),
      "current site overhang is used"
    );

    await click(".duc-cosmetics-section-heading .btn");

    assert.strictEqual(this.currentUser.cosmetics.avatar_frame, null);
    assert.strictEqual(
      document.getElementById(CURRENT_USER_STYLE_ID),
      null,
      "current-user frame style is removed"
    );
    assert.notStrictEqual(
      link.href,
      originalHref,
      "the shared frames/nameplates stylesheet is refreshed"
    );

    if (createdLink) {
      link.remove();
    } else {
      link.href = originalHref;
    }
  });
});
