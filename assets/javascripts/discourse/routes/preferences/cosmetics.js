import { service } from "@ember/service";
import { defaultHomepage } from "discourse/lib/utilities";
import RestrictedUserRoute from "discourse/routes/restricted-user";

export default class PreferencesCosmeticsRoute extends RestrictedUserRoute {
  @service router;
  @service siteSettings;

  showFooter = true;

  setupController(controller, user) {
    if (!this.siteSettings.discourse_user_cosmetics_enabled) {
      return this.router.transitionTo(`discovery.${defaultHomepage()}`);
    }

    controller.set("model", user);
  }
}
