import { module, test } from "qunit";
import {
  POST_AVATAR_FRAME_CLASS_PREFIX,
  postAvatarFrameClassTransformer,
} from "discourse/plugins/discourse-user-cosmetics/discourse/lib/duc-post-avatar-frame";

module("Unit | Lib | duc-post-avatar-frame", function () {
  test("adds a stable numeric user-id class from the post transformer context", function (assert) {
    const value = ["existing-class"];

    const result = postAvatarFrameClassTransformer({
      value,
      context: { post: { user_id: 42 }, user: { id: 99 } },
    });

    assert.strictEqual(result, value, "preserves the transformer value array");
    assert.deepEqual(result, [
      "existing-class",
      `${POST_AVATAR_FRAME_CLASS_PREFIX}42`,
    ]);
  });

  test("falls back to the transformer user context and avoids duplicates", function (assert) {
    const className = `${POST_AVATAR_FRAME_CLASS_PREFIX}7`;
    const value = [className];

    const result = postAvatarFrameClassTransformer({
      value,
      context: { user: { id: 7 } },
    });

    assert.deepEqual(result, [className]);
  });

  test("leaves the class list untouched when no user identity is available", function (assert) {
    const value = ["existing-class"];

    const result = postAvatarFrameClassTransformer({ value, context: {} });

    assert.strictEqual(result, value);
    assert.deepEqual(result, ["existing-class"]);
  });
});
