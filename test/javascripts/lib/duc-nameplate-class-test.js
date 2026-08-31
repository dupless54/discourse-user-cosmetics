import { module, test } from "qunit";
import {
  MENTION_NAMEPLATE_CLASS_PREFIX,
  POST_NAMEPLATE_CLASS_PREFIX,
  mentionNameplateClassTransformer,
  postNameplateClassTransformer,
} from "discourse/plugins/discourse-user-cosmetics/discourse/lib/duc-nameplate-class";

module("Unit | Lib | duc-nameplate-class", function () {
  test("adds a stable post-author class from the current transformer context", function (assert) {
    const value = ["existing-class"];

    const result = postNameplateClassTransformer({
      value,
      context: { user: { id: 42 }, post: { user_id: 99 } },
    });

    assert.strictEqual(result, value, "preserves the transformer value array");
    assert.deepEqual(result, [
      "existing-class",
      `${POST_NAMEPLATE_CLASS_PREFIX}42`,
    ]);
  });

  test("falls back to the post user id and avoids duplicate post classes", function (assert) {
    const className = `${POST_NAMEPLATE_CLASS_PREFIX}7`;
    const value = [className];

    const result = postNameplateClassTransformer({
      value,
      context: { post: { user_id: 7 } },
    });

    assert.deepEqual(result, [className]);
  });

  test("adds a stable cooked-mention class from the mention user context", function (assert) {
    const value = [];

    const result = mentionNameplateClassTransformer({
      value,
      context: { user: { id: 11 } },
    });

    assert.deepEqual(result, [`${MENTION_NAMEPLATE_CLASS_PREFIX}11`]);
  });

  test("leaves class lists untouched when no user identity is available", function (assert) {
    const postValue = ["post-existing"];
    const mentionValue = ["mention-existing"];

    assert.strictEqual(
      postNameplateClassTransformer({ value: postValue, context: {} }),
      postValue
    );
    assert.deepEqual(postValue, ["post-existing"]);

    assert.strictEqual(
      mentionNameplateClassTransformer({ value: mentionValue, context: {} }),
      mentionValue
    );
    assert.deepEqual(mentionValue, ["mention-existing"]);
  });
});
