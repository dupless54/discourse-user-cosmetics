import Component from "@glimmer/component";
import { set } from "@ember/object";
import { service } from "@ember/service";
import {
  COSMETICS_CHANGE_EVENT,
  cosmeticsUsername,
  fetchLatestCosmetics,
  matchesCosmeticsChange,
} from "../lib/duc-live-cosmetics";

export default class UserCosmeticsLiveSync extends Component {
  @service appEvents;
  @service currentUser;

  constructor() {
    super(...arguments);
    this.appEvents.on(
      COSMETICS_CHANGE_EVENT,
      this,
      this.refreshVisibleUserCosmetics
    );
    this.reconcileVisibleCurrentUser();
  }

  willDestroy() {
    this.appEvents.off(
      COSMETICS_CHANGE_EVENT,
      this,
      this.refreshVisibleUserCosmetics
    );
    super.willDestroy(...arguments);
  }

  get user() {
    return (
      this.args.outletArgs?.user ??
      this.args.outletArgs?.model ??
      this.args.model
    );
  }

  reconcileVisibleCurrentUser() {
    const user = this.user;
    if (
      !user ||
      this.currentUser?.cosmetics === undefined ||
      !matchesCosmeticsChange(user, { user_id: this.currentUser?.id })
    ) {
      return;
    }

    set(user, "cosmetics", this.currentUser.cosmetics);
  }

  async refreshVisibleUserCosmetics(data) {
    const user = this.user;
    if (!matchesCosmeticsChange(user, data)) {
      return;
    }

    if (data?.cosmetics !== undefined) {
      set(user, "cosmetics", data.cosmetics);
      return;
    }

    const cosmetics = await fetchLatestCosmetics(cosmeticsUsername(user));
    if (cosmetics === undefined || this.user !== user) {
      return;
    }

    set(user, "cosmetics", cosmetics);
  }

  <template></template>
}
