import RouteTemplate from "ember-route-template";
import UserCosmeticsAdminPage from "../../components/user-cosmetics-admin-page";

export default RouteTemplate(
  <template><UserCosmeticsAdminPage @model={{@model}} /></template>
);
