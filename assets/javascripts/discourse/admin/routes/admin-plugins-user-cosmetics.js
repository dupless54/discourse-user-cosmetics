import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class AdminPluginsUserCosmeticsRoute extends Route {
  model() {
    return ajax("/admin/plugins/user-cosmetics/items.json");
  }
}
