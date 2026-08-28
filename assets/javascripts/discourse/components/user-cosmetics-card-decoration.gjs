import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { get } from "@ember/object";
import { htmlSafe } from "@ember/template";
import { later, cancel } from "@ember/runloop"; // Ember zamanlayıcıları
import { modifier } from "ember-modifier";

const CARD_SELECTOR = "#user-card, .user-card";

// The outlet lives inside Discourse's metadata area. Rendering the image
// there makes absolute sizing depend on whichever nested element happens to
// be positioned by the active theme. Mount a dedicated image directly under
// the real user-card instead, so Crimson Channels is always the size source.
const attachCardDecoration = modifier((element, [imageUrl]) => {
  const card = element.closest(CARD_SELECTOR);

  if (!card || !imageUrl) {
    return;
  }

  card
    .querySelector(":scope > .duc-card-decoration-overlay")
    ?.remove();

  const image = document.createElement("img");
  image.src = imageUrl;
  image.alt = "";
  image.draggable = false;
  image.setAttribute("aria-hidden", "true");
  image.className =
    "duc-profile-effect-overlay duc-card-decoration-overlay";
  card.appendChild(image);

  return () => image.remove();
});

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
    return get(this.user, "cosmetics")?.card_decoration;
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
          <span
            class="duc-card-decoration-anchor"
            {{attachCardDecoration this.decoration.image_url}}
          ></span>
        {{/if}}
      {{else if this.decoration.gradient_from}}
        <div class="duc-card-banner" style={{this.bannerStyle}}>
          <span class="duc-card-banner-label">{{this.decoration.name}}</span>
        </div>
      {{/if}}

    {{/if}}
  </template>
}
