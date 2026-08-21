import Component from "@glimmer/component";
import { htmlSafe } from "@ember/template"; // Ember'ın güvenlik kilidini açıyoruz

export default class UserCosmeticsNameplate extends Component {
  get user() {
    return (
      this.args.outletArgs?.user ??
      this.args.outletArgs?.model ??
      this.args.model
    );
  }

  get nameplate() {
    return this.user?.cosmetics?.nameplate;
  }

  get stripStyle() {
    const n = this.nameplate;
    if (!n) {
      return htmlSafe(""); // Çıktıları htmlSafe ile sarıyoruz
    }
    if (n.image_url) {
      return htmlSafe(`background-image: url("${n.image_url}");`);
    }
    if (n.gradient_from && n.gradient_to) {
      return htmlSafe(`background-image: linear-gradient(90deg, ${n.gradient_from}, ${n.gradient_to});`);
    }
    return htmlSafe("");
  }

  <template>
    {{#if this.nameplate}}
      <div class="duc-nameplate">
        <span class="duc-nameplate-glow" style={{this.stripStyle}}></span>
        <span class="duc-nameplate-label">{{this.nameplate.name}}</span>
      </div>
    {{/if}}
  </template>
}