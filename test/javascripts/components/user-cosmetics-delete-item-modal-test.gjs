import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import UserCosmeticsDeleteItemModal from "discourse/plugins/discourse-user-cosmetics/discourse/admin/components/modal/user-cosmetics-delete-item";

module("Component | UserCosmeticsDeleteItemModal", function (hooks) {
  setupRenderingTest(hooks);

  test("renders a Discourse DModal confirmation for the selected cosmetic", async function (assert) {
    this.model = {
      item: {
        id: 1,
        name: "Gold Frame",
      },
      onDeleted: () => {},
    };
    this.closeModal = () => {};

    await render(
      <template>
        <UserCosmeticsDeleteItemModal
          @model={{this.model}}
          @closeModal={{this.closeModal}}
          @inline={{true}}
        />
      </template>
    );

    assert.dom(".d-modal").exists();
    assert.dom(".duc-delete-item-modal").exists();
    assert
      .dom(".duc-delete-item-modal__message")
      .includesText("Gold Frame")
      .includesText("can't be undone");
    assert.dom(".duc-delete-item-modal__confirm.btn-danger").exists();
  });
});
