import Component from "@glimmer/component";
import { modifier } from "ember-modifier";
import { htmlSafe } from "@ember/template";

const PORTAL_CLASS = "duc-profile-effect-portal";
const CARD_SELECTOR = "#user-card, .user-card"; 

const attachProfileEffect = modifier((element, [effect]) => {
  const card = element.closest(CARD_SELECTOR);

  if (!card || !effect || !Array.isArray(effect.layers) || effect.layers.length === 0) {
    return;
  }

  // 1. DİSCORD MANTIĞI: Efekti kartın içine değil, SAYFANIN EN DIŞINA (body) ekliyoruz. 
  // Bu sayede kartı bir "sandviç" gibi arasına alabileceğiz.
  const portal = document.createElement("div");
  portal.className = PORTAL_CLASS;
  portal.style.position = "absolute";
  portal.style.pointerEvents = "none";
  // DİKKAT: Portalın kendisine z-index VERMİYORUZ ki içindeki resimler serbest kalsın.
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
      
      // Resimler, kendi yerleşimlerine göre CSS z-index değişkenini alacak
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
    const innerWidth = effect.effect_inner_width || effect.inner_width || 1200;
    const scale = rect.width / innerWidth;
    
    const overflowH = (effect.effect_overflow_horizontal || effect.overflow_horizontal || 0) * scale;
    const overflowTop = (effect.effect_overflow_top || effect.overflow_top || 0) * scale;
    const overflowBottom = (effect.effect_overflow_bottom || effect.overflow_bottom || 0) * scale;

    // Portalı karta milimetrik olarak hizalıyoruz
    portal.style.left = `${rect.left + window.scrollX - overflowH}px`;
    portal.style.top = `${rect.top + window.scrollY - overflowTop}px`;
    portal.style.width = `${rect.width + overflowH * 2}px`;
    portal.style.height = `${rect.height + overflowTop + overflowBottom}px`;

    // 2. KUSURSUZ DERİNLİK HESAPLAMASI (Sandviçleme)
    // Kartın sistemdeki katman numarasını (z-index) öğreniyoruz
    let cardZ = parseInt(getComputedStyle(card).zIndex, 10);
    
    if (!Number.isFinite(cardZ)) {
      cardZ = 1000;
      card.style.zIndex = cardZ;
      if (getComputedStyle(card).position === "static") {
        card.style.position = "relative";
      }
    }

    // ARKA (Back) katmanları kartın 1 seviye arkasına (cardZ - 1)
    // ÖN (Front) katmanları kartın 1 seviye önüne (cardZ + 1) atıyoruz!
    portal.style.setProperty("--duc-effect-back-z", cardZ - 1);
    portal.style.setProperty("--duc-effect-front-z", cardZ + 1);
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