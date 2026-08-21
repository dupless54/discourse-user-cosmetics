import Component from "@glimmer/component";

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
      return "";
    }
    if (n.image_url) {
      return `background-image: url("${n.image_url}");`;
    }
    if (n.gradient_from && n.gradient_to) {
      return `background-image: linear-gradient(90deg, ${n.gradient_from}, ${n.gradient_to});`;
    }
    return "";
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
