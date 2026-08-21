import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import DButton from "discourse/components/d-button";
import UserCosmeticsPicker from "./user-cosmetics-picker";
import { t } from "../lib/duc-i18n";

export default class UserCosmeticsPreferencesEntry extends Component {
  @tracked showPicker = false;

  @action
  open() {
    this.showPicker = true;
  }

  @action
  close() {
    this.showPicker = false;
  }

  <template>
    <div class="control-group duc-preferences-entry">
      <label class="control-label">{{t "discourse_user_cosmetics.preferences.title"}}</label>
      <div class="controls">
        <p class="duc-preferences-description">
          {{t "discourse_user_cosmetics.preferences.description"}}
        </p>
        <DButton
          @icon="wand-magic-sparkles"
          @translatedLabel={{t "discourse_user_cosmetics.preferences.open"}}
          @action={{this.open}}
          class="duc-open-picker-btn"
        />
      </div>
    </div>

    {{#if this.showPicker}}
      <UserCosmeticsPicker @onClose={{this.close}} />
    {{/if}}
  </template>
}
