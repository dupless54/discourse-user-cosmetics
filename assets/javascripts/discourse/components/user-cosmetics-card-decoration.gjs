import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { htmlSafe } from "@ember/template";
import { later, cancel } from "@ember/runloop"; // Ember zamanlayıcıları

export default class UserCosmeticsCardDecoration extends Component {
  @tracked isPlaying = true;
  timer = null;

  constructor() {
    super(...arguments);
    this.startLoop();
  }

  startLoop() {
    // Sadece görsel efekt varsa döngüyü başlat
    if (this.decoration?.image_url) {
      this.scheduleNextToggle();
    }
  }

  scheduleNextToggle() {
    // isPlaying true ise 4000ms (4 saniye) oynat, false ise 10000ms (10 saniye) bekle
    const delay = this.isPlaying ? 4000 : 10000;

    this.timer = later(
      this,
      () => {
        this.isPlaying = !this.isPlaying; // Durumu tersine çevir
        this.scheduleNextToggle(); // Bir sonraki aşamayı zamanla
      },
      delay
    );
  }

  willDestroy() {
    super.willDestroy();
    // Kullanıcı kartı kapattığında zamanlayıcıyı temizle (Hafıza sızıntısını önler)
    if (this.timer) {
      cancel(this.timer);
    }
  }

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

  get effectStyle() {
    const d = this.decoration;
    if (!d || !d.image_url) {
      return htmlSafe("");
    }
    return htmlSafe(`background-image: url("${d.image_url}");`);
  }

  get bannerStyle() {
    const d = this.decoration;
    if (!d || !d.gradient_from || !d.gradient_to) {
      return htmlSafe("");
    }
    return htmlSafe(
      `background: linear-gradient(135deg, ${d.gradient_from}, ${d.gradient_to});`
    );
  }

  <template>
    {{#if this.decoration}}
      
      {{#if this.decoration.image_url}}
        {{!-- Efekt sadece isPlaying true olduğunda HTML'e eklenir, false olunca silinir --}}
        {{#if this.isPlaying}}
          <div class="duc-profile-effect-overlay" style={{this.effectStyle}}></div>
        {{/if}}
      {{else if this.decoration.gradient_from}}
        <div class="duc-card-banner" style={{this.bannerStyle}}>
          <span class="duc-card-banner-label">{{this.decoration.name}}</span>
        </div>
      {{/if}}

    {{/if}}
  </template>
}