import Component from "@glimmer/component";
import { LinkTo } from "@ember/routing";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { hasEnabledCosmetics } from "../../lib/duc-cosmetic-kinds";

export default class UserCosmeticsPreferencesNav extends Component {
  static shouldRender(_args, { siteSettings }) {
    return hasEnabledCosmetics(siteSettings);
  }

  <template>
    <li class="user-nav__preferences-cosmetics">
      <LinkTo @route="preferences.cosmetics">
        {{dIcon "wand-magic-sparkles"}}
        <span>{{i18n "discourse_user_cosmetics.preferences.title"}}</span>
      </LinkTo>
    </li>
  </template>
}
