import Component from "@glimmer/component";
import { LinkTo } from "@ember/routing";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { t } from "../../lib/duc-i18n";

export default class UserCosmeticsPreferencesNav extends Component {
  static shouldRender(_args, { siteSettings }) {
    return siteSettings.discourse_user_cosmetics_enabled;
  }

  <template>
    <li class="user-nav__preferences-cosmetics">
      <LinkTo @route="preferences.cosmetics">
        {{dIcon "wand-magic-sparkles"}}
        <span>{{t "discourse_user_cosmetics.preferences.title"}}</span>
      </LinkTo>
    </li>
  </template>
}
