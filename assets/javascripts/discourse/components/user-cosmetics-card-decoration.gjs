import Component from "@glimmer/component";

export default class UserCosmeticsCardDecoration extends Component {
  get user() {
    return (
      this.args.outletArgs?.user ??
      this.args.outletArgs?.model ??
      this.args.model
    );
  }

  get decoration() {
    return this.user?.cosmetics?.card_decoration;
  }

  get bannerStyle() {
    const d = this.decoration;
    if (!d) {
      return "";
    }
    if (d.image_url) {
      return `background-image: url("${d.image_url}");`;
    }
    if (d.gradient_from && d.gradient_to) {
      return `background-image: linear-gradient(135deg, ${d.gradient_from}, ${d.gradient_to});`;
    }
    return "";
  }

  <template>
    {{#if this.decoration}}
      <div class="duc-card-banner" style={{this.bannerStyle}}>
        <span class="duc-card-banner-label">{{this.decoration.name}}</span>
      </div>
    {{/if}}
  </template>
}
