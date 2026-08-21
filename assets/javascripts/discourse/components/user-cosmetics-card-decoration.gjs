import Component from "@glimmer/component";
import { htmlSafe } from "@ember/template";

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

  // Animasyonlu görsel için stil (Discord tarzı efekt)
  get effectStyle() {
    const d = this.decoration;
    if (!d || !d.image_url) {
      return htmlSafe("");
    }
    return htmlSafe(`background-image: url("${d.image_url}");`);
  }

  // Sadece renk seçildiyse arka plan afişi için stil
  get bannerStyle() {
    const d = this.decoration;
    if (!d || !d.gradient_from || !d.gradient_to) {
      return htmlSafe("");
    }
    return htmlSafe(`background: linear-gradient(135deg, ${d.gradient_from}, ${d.gradient_to});`);
  }

  <template>
    {{#if this.decoration}}
      
      {{#if this.decoration.image_url}}
        {{!-- DİSCORD TARZI ÖN PLAN EFEKTİ --}}
        <div class="duc-profile-effect-overlay" style={{this.effectStyle}}></div>
      {{else if this.decoration.gradient_from}}
        {{!-- ESKİ TARZ ARKA PLAN AFİŞİ --}}
        <div class="duc-card-banner" style={{this.bannerStyle}}>
          <span class="duc-card-banner-label">{{this.decoration.name}}</span>
        </div>
      {{/if}}

    {{/if}}
  </template>
}