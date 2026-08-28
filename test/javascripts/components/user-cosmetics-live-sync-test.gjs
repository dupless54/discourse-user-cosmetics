import EmberObject from "@ember/object";
import { render, settled } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import UserCosmeticsLiveSync from "discourse/plugins/discourse-user-cosmetics/discourse/components/user-cosmetics-live-sync";
import UserCosmeticsNameplate from "discourse/plugins/discourse-user-cosmetics/discourse/components/user-cosmetics-nameplate";
import { FRAMES_CSS_LINK_ID } from "discourse/plugins/discourse-user-cosmetics/discourse/lib/duc-current-user-presentation";
import { COSMETICS_CHANGE_EVENT } from "discourse/plugins/discourse-user-cosmetics/discourse/lib/duc-live-cosmetics";
import {
  installCosmeticsResumeSync,
  reconcileCurrentUserCosmetics,
} from "discourse/plugins/discourse-user-cosmetics/discourse/lib/duc-resume-sync";

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

    this.freshCosmetics = {
      avatar_frame: null,
      nameplate: {
        id: 2,
        name: "Fresh plate",
        gradient_from: "#333333",
        gradient_to: "#444444",
      },
      card_decoration: null,
      profile_effect: null,
    };

    this.cardRequests = 0;
    this.cardUrls = [];
    pretender.get("/u/alice/card.json", (request) => {
      this.cardRequests += 1;
      this.cardUrls.push(request.url);
      return response({
        user: {
          id: 7,
          username: "alice",
          username_lower: "alice",
          cosmetics: this.freshCosmetics,
        },
      });
    });
  });

  hooks.afterEach(function () {
    document.getElementById(FRAMES_CSS_LINK_ID)?.remove();
  });

  test("reloads and rerenders the visible user's cosmetics after a live marker", async function (assert) {
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

  test("uses a reconciled resume payload without fetching the same user twice", async function (assert) {
    await render(
      <template>
        <UserCosmeticsLiveSync @model={{this.user}} />
        <UserCosmeticsNameplate @model={{this.user}} />
      </template>
    );

    this.owner.lookup("service:app-events").trigger(COSMETICS_CHANGE_EVENT, {
      user_id: 7,
      kind: "resume",
      cosmetics: this.freshCosmetics,
    });
    await settled();

    assert.strictEqual(this.cardRequests, 0, "the inline resume payload is reused");
    assert.strictEqual(this.user.cosmetics.nameplate.id, 2);
    assert.dom("style").hasTextContaining("#333333");
  });

  test("late-mounted current-user surfaces reuse already reconciled cosmetics", async function (assert) {
    this.currentUser.setProperties({
      id: 7,
      username: "alice",
      username_lower: "alice",
      cosmetics: this.freshCosmetics,
    });

    await render(
      <template>
        <UserCosmeticsLiveSync @model={{this.user}} />
        <UserCosmeticsNameplate @model={{this.user}} />
      </template>
    );

    assert.strictEqual(this.cardRequests, 0, "no duplicate card request is needed");
    assert.strictEqual(this.user.cosmetics.nameplate.id, 2);
    assert.dom("style").hasTextContaining("#333333");
  });

  test("reconciles stale cosmetics and shared CSS on a normal page bootstrap", async function (assert) {
    await render(
      <template>
        <UserCosmeticsLiveSync @model={{this.user}} />
        <UserCosmeticsNameplate @model={{this.user}} />
      </template>
    );

    const link = document.createElement("link");
    link.id = FRAMES_CSS_LINK_ID;
    link.rel = "stylesheet";
    link.href = "/user-cosmetics/frames.css";
    document.head.appendChild(link);

    const documentObject = new EventTarget();
    documentObject.visibilityState = "visible";
    const windowObject = new EventTarget();
    const cleanup = installCosmeticsResumeSync({
      currentUser: this.user,
      siteSettings: this.owner.lookup("service:site-settings"),
      appEvents: this.owner.lookup("service:app-events"),
      documentObject,
      windowObject,
    });

    await settled();
    cleanup();

    assert.strictEqual(this.cardRequests, 1, "bootstrap performs one server reconciliation");
    assert.true(
      this.cardUrls[0].includes("duc_refresh="),
      "bootstrap bypasses stale card caches"
    );
    assert.true(
      new URL(link.href).searchParams.has("duc_refresh"),
      "bootstrap cache-busts the shared cosmetics stylesheet"
    );
    assert.strictEqual(this.user.cosmetics.nameplate.id, 2);
    assert.dom("style").hasTextContaining("#333333");
  });

  test("keeps all cosmetics removed after a normal page bootstrap", async function (assert) {
    this.user.set("cosmetics", {
      avatar_frame: { id: 10, image_url: "/old-frame.png" },
      nameplate: {
        id: 11,
        name: "Old plate",
        gradient_from: "#111111",
        gradient_to: "#222222",
      },
      card_decoration: { id: 12, image_url: "/old-card.png" },
      profile_effect: { id: 13, image_url: "/old-effect.png" },
    });
    this.freshCosmetics = {
      avatar_frame: null,
      nameplate: null,
      card_decoration: null,
      profile_effect: null,
    };

    await render(
      <template>
        <UserCosmeticsLiveSync @model={{this.user}} />
        <UserCosmeticsNameplate @model={{this.user}} />
      </template>
    );

    const documentObject = new EventTarget();
    documentObject.visibilityState = "visible";
    const windowObject = new EventTarget();
    const cleanup = installCosmeticsResumeSync({
      currentUser: this.user,
      siteSettings: this.owner.lookup("service:site-settings"),
      appEvents: this.owner.lookup("service:app-events"),
      documentObject,
      windowObject,
    });

    await settled();
    cleanup();

    assert.deepEqual(this.user.cosmetics, this.freshCosmetics);
    assert.dom("style").doesNotExist("removed nameplate presentation stays removed");
  });

  test("reconciles stale cosmetics when a suspended mobile page becomes visible", async function (assert) {
    await render(
      <template>
        <UserCosmeticsLiveSync @model={{this.user}} />
        <UserCosmeticsNameplate @model={{this.user}} />
      </template>
    );

    const documentObject = new EventTarget();
    documentObject.visibilityState = "visible";
    const windowObject = new EventTarget();
    const cleanup = installCosmeticsResumeSync({
      currentUser: this.user,
      siteSettings: this.owner.lookup("service:site-settings"),
      appEvents: this.owner.lookup("service:app-events"),
      documentObject,
      windowObject,
      syncOnInstall: false,
    });

    documentObject.visibilityState = "hidden";
    documentObject.dispatchEvent(new Event("visibilitychange"));
    documentObject.visibilityState = "visible";
    documentObject.dispatchEvent(new Event("visibilitychange"));
    await settled();
    cleanup();

    assert.strictEqual(this.cardRequests, 1, "resume performs one server reconciliation");
    assert.true(
      this.cardUrls[0].includes("duc_refresh="),
      "resume bypasses a stale mobile card cache"
    );
    assert.strictEqual(this.user.cosmetics.nameplate.id, 2);
    assert.dom("style").hasTextContaining("#333333");
  });

  test("direct reconciliation refreshes the current user from server truth", async function (assert) {
    const cosmetics = await reconcileCurrentUserCosmetics({
      currentUser: this.user,
      siteSettings: this.owner.lookup("service:site-settings"),
      appEvents: this.owner.lookup("service:app-events"),
      refreshStylesheet: false,
    });

    assert.strictEqual(this.cardRequests, 1);
    assert.true(this.cardUrls[0].includes("duc_refresh="));
    assert.strictEqual(cosmetics.nameplate.id, 2);
    assert.strictEqual(this.user.cosmetics.nameplate.id, 2);
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
