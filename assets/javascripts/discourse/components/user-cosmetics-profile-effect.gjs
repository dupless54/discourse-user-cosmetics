import Component from "@glimmer/component";
import { modifier } from "ember-modifier";
import { htmlSafe } from "@ember/template";

const PORTAL_CLASS = "duc-profile-effect-portal";

// HATA 1 ÇÖZÜLDÜ: .user-profile ve .user-main silindi! Sadece kullanıcı kartını hedefliyoruz.
const CARD_SELECTOR = "#user-card, .user-card"; 

const attachProfileEffect = modifier((element, [effect]) => {
  const card = element.closest(CARD_SELECTOR);

  if (!card || !effect || !Array.isArray(effect.layers) || effect.layers.length === 0) {
    return;
  }

  // HATA 2 ÇÖZÜLDÜ: Gerçek Sandviçleme (3D Derinlik)
  // Kartı izole bir katman olmaya zorluyoruz ki arkasına ve önüne güvenle eleman atabilelim.
  let cardZ = parseInt(getComputedStyle(card).zIndex, 10);
  if (!Number.isFinite(cardZ)) {
    cardZ = 1000; // Sabit güçlü bir katman değeri
  }
  
  card.style.zIndex = cardZ;
  if (getComputedStyle(card).position === "static") {
    card.style.position = "relative";
  }

  const portal = document.createElement("div");
  portal.className = PORTAL_CLASS;
  portal.style.position = "absolute";
  portal.style.pointerEvents = "none";
  // Portal sayfanın en dışına eklenir ki taşmalar (overflow) kesilmesin.
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
      
      // DİSCORD MANTIĞI UYGULANDI:
      // Ön (front) katmanlar kartın önüne (cardZ + 1)
      // Arka (back) katmanlar kartın GERÇEKTEN arkasına (cardZ - 1)
      img.style.zIndex = layer.stack_order === "front" ? (cardZ + 1) : (cardZ - 1);
      
      portal.appendChild(img);
      return img;
    });

  function layout() {
    if (!document.body.contains(card)) {
      return;
    }

    const rect = card.getBoundingClientRect();
    const innerWidth = effect.effect_inner_width || effect.inner_width || 1200;
    const scale = rect.width / innerWidth;
    
    const overflowH = (effect.effect_overflow_horizontal || effect.overflow_horizontal || 0) * scale;
    const overflowTop = (effect.effect_overflow_top || effect.overflow_top || 0) * scale;
    const overflowBottom = (effect.effect_overflow_bottom || effect.overflow_bottom || 0) * scale;

    portal.style.left = `${rect.left + window.scrollX - overflowH}px`;
    portal.style.top = `${rect.top + window.scrollY - overflowTop}px`;
    portal.style.width = `${rect.width + overflowH * 2}px`;
    portal.style.height = `${rect.height + overflowTop + overflowBottom}px`;
    
    // HATA 3 ÇÖZÜLDÜ: Sizin yakaladığınız .user-card-avatar detayını kullanarak avatarı sağlama alıyoruz!
    const avatar = card.querySelector('.user-card-avatar');
    if(avatar) {
      avatar.style.position = "relative";
      avatar.style.zIndex = "5"; // Kartın kendi içinde daima önde kalmasını sağlıyoruz
    }
  }

  layout();

  let resizeObserver;
  if (typeof ResizeObserver !== "undefined") {
    resizeObserver = new ResizeObserver(layout);
    resizeObserver.observe(card);
  }

  return () => {
    resizeObserver?.disconnect();
    if (document.body.contains(portal)) {
      portal.remove();
    }
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

  get globalStyle() {
    if (!this.effect) return htmlSafe("");
    return htmlSafe(`
      #user-card, .user-card {
        overflow: visible !important;
      }
    `);
  }

  <template>
    {{#if this.effect}}
      <style>{{this.globalStyle}}</style>
      <div class="duc-profile-effect-anchor" {{attachProfileEffect this.effect}}></div>
    {{/if}}
  </template>
}