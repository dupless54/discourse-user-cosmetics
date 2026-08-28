import { service } from "@ember/service";
import { hasEnabledCosmetics } from "discourse/plugins/discourse-user-cosmetics/discourse/lib/duc-cosmetic-kinds";
import { defaultHomepage } from "discourse/lib/utilities";
import RestrictedUserRoute from "discourse/routes/restricted-user";

export default class PreferencesCosmeticsRoute extends RestrictedUserRoute {
  @service router;
  @service siteSettings;

  showFooter = true;

  setupController(controller, user) {
    if (!hasEnabledCosmetics(this.siteSettings)) {
      return this.router.transitionTo(`discovery.${defaultHomepage()}`);
    }

    controller.set("model", user);
  }
}
