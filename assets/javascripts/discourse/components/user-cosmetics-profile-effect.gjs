import Component from "@glimmer/component";
import { modifier } from "ember-modifier"; // Hatanın çözümü: Modifier kütüphanesini dahil ettik

const PORTAL_CLASS = "duc-profile-effect-portal";
const CARD_SELECTOR = "#user-card, .user-card, .user-profile, .user-main";

// Normal fonksiyonu, Ember'ın anlayacağı "modifier" yapısı ile sarmalıyoruz
const attachProfileEffect = modifier((element, [effect]) => {
  const card = element.closest(CARD_SELECTOR);

  if (!card || !effect || !Array.isArray(effect.layers) || effect.layers.length === 0) {
    return;
  }

  const portal = document.createElement("div");
  portal.className = PORTAL_CLASS;
  portal.style.position = "absolute";
  portal.style.pointerEvents = "none";
  document.body.appendChild(portal);

  const images = effect.layers
    .filter((layer) => layer && layer.image_url)
    .map((layer) => {
      const img = document.createElement("img");
      img.src = layer.image_url;
      img.alt = "";
      img.className = "duc-profile-effect-layer";
      img.dataset.anchor = layer.anchor;
      img.dataset.stackOrder = layer.stack_order;
      img.style.position = "absolute";
      img.style.left = "0";
      img.style.width = "100%";
      img.style.height = "auto";
      img.style.display = "block";
      img.style[layer.anchor === "top" ? "top" : "bottom"] = "0";
      img.style.zIndex =
        layer.stack_order === "front"
          ? "var(--duc-effect-front-z)"
          : "var(--duc-effect-back-z)";
      portal.appendChild(img);
      return img;
    });

  function layout() {
    if (!document.body.contains(card)) {
      return;
    }

    const rect = card.getBoundingClientRect();
    const innerWidth = effect.inner_width || 1200;
    const scale = rect.width / innerWidth;
    const overflowH = (effect.overflow_horizontal || 0) * scale;
    const overflowTop = (effect.overflow_top || 0) * scale;
    const overflowBottom = (effect.overflow_bottom || 0) * scale;

    portal.style.left = `${rect.left + window.scrollX - overflowH}px`;
    portal.style.top = `${rect.top + window.scrollY - overflowTop}px`;
    portal.style.width = `${rect.width + overflowH * 2}px`;
    portal.style.height = `${rect.height + overflowTop + overflowBottom}px`;

    const cardZ = parseInt(getComputedStyle(card).zIndex, 10);
    const baseZ = Number.isFinite(cardZ) ? cardZ : 10000;
    portal.style.setProperty("--duc-effect-back-z", baseZ - 1);
    portal.style.setProperty("--duc-effect-front-z", baseZ + 1);
  }

  layout();

  let resizeObserver;
  if (typeof ResizeObserver !== "undefined") {
    resizeObserver = new ResizeObserver(layout);
    resizeObserver.observe(card);
  }

  return () => {
    resizeObserver?.disconnect();
    portal.remove();
    images.length = 0;
  };
});

export default class UserCosmeticsProfileEffect extends Component {
  get user() {
    return (
      this.args.outletArgs?.user ??
      this.args.outletArgs?.model ??
      this.args.model
    );
  }

  get effect() {
    return this.user?.cosmetics?.profile_effect;
  }

  <template>
    <div class="duc-profile-effect-anchor" {{attachProfileEffect this.effect}}></div>
  </template>
}