import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DButton from "discourse/ui-kit/d-button";
import DModal from "discourse/ui-kit/d-modal";
import DModalCancel from "discourse/ui-kit/d-modal-cancel";
import { t } from "../../../lib/duc-i18n";

export default class UserCosmeticsDeleteItemModal extends Component {
  @tracked deleting = false;

  get item() {
    return this.args.model.item;
  }

  get message() {
    return t("discourse_user_cosmetics.admin.delete_confirm", {
      name: this.item.name,
    });
  }

  @action
  async deleteItem() {
    if (this.deleting) {
      return;
    }

    this.deleting = true;

    try {
      await ajax(`/admin/plugins/user-cosmetics/items/${this.item.id}.json`, {
        type: "DELETE",
      });
      this.args.model.onDeleted?.(this.item);
      this.args.closeModal(true);
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.deleting = false;
    }
  }

  <template>
    <DModal
      @closeModal={{@closeModal}}
      @inline={{@inline}}
      @title={{t "discourse_user_cosmetics.admin.delete"}}
      class="duc-delete-item-modal"
    >
      <:body>
        <p class="duc-delete-item-modal__message">{{this.message}}</p>
      </:body>
      <:footer>
        <DButton
          @icon="trash-can"
          @translatedLabel={{t "discourse_user_cosmetics.admin.delete"}}
          @action={{this.deleteItem}}
          @isLoading={{this.deleting}}
          class="btn-danger duc-delete-item-modal__confirm"
        />
        {{#unless this.deleting}}
          <DModalCancel @close={{@closeModal}} />
        {{/unless}}
      </:footer>
    </DModal>
  </template>
}
