import Component from "@glimmer/component";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
import { i18n } from "discourse-i18n";

const MessageIcon = <template>
  <svg
    viewBox="0 0 24 24"
    width="18"
    height="18"
    fill="currentColor"
    aria-hidden="true"
    class="duc-icon"
  >
    <path
      d="M20 2H4a2 2 0 0 0-2 2v14l4-4h14a2 2 0 0 0 2-2V4a2 2 0 0 0-2-2Zm-2 8H6V8h12v2Zm0-3H6V5h12v2Z"
    ></path>
  </svg>
</template>;

export default class UserCosmeticsCardMessage extends Component {
  @service composer;
  @service currentUser;

  get user() {
    return this.args.outletArgs?.user;
  }

  get username() {
    return this.user?.username;
  }

  get canMessage() {
    return Boolean(
      this.currentUser &&
        this.username &&
        this.currentUser.username !== this.username &&
        this.user?.can_send_private_message_to_user
    );
  }

  get label() {
    return i18n("discourse_user_cosmetics.user_card.message", {
      username: this.username,
    });
  }

  @action
  composeMessage() {
    if (!this.canMessage) {
      return;
    }

    this.args.outletArgs?.close?.();
    this.composer.openNewMessage({ recipients: this.username });
  }

  <template>
    {{#if this.canMessage}}
      <button
        type="button"
        class="duc-user-card-message"
        title={{this.label}}
        {{on "click" this.composeMessage}}
      >
        <span class="duc-user-card-message__label">{{this.label}}</span>
        <span class="duc-user-card-message__icon"><MessageIcon /></span>
      </button>
    {{/if}}
  </template>
}
