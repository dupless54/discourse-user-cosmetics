import Component from "@glimmer/component";
import { modifier } from "ember-modifier";
import { htmlSafe } from "@ember/template";

const CARD_SELECTOR = "#user-card, .user-card"; 

const attachProfileEffect = modifier((element, [effect]) => {
  const card = element.closest(CARD_SELECTOR);

  if (!card || !effect || !Array.isArray(effect.layers) || effect.layers.length === 0) {
    return;
  }

  // Kartın kapsayıcısını buluyoruz (Sandviçi burada yapacağız)
  const parent = card.parentElement;
  if (!parent) return;

  // 1. GERÇEK DİSCORD SANDVİÇLEMESİ:
  // Kapsayıcıyı referans noktası yapıp, dışarı taşmaları serbest bırakıyoruz
  if (getComputedStyle(parent).position === "static") {
    parent.style.position = "relative";
  }
  parent.style.overflow = "visible";
  // Z-index savaşlarının site geneline yayılmasını engelliyoruz
  parent.style.isolation = "isolate";

  // Arka Katman (Kartın ve avatarın arkasında kalacak bölüm)
  const backPortal = document.createElement("div");
  backPortal.className = "duc-profile-effect-portal-back";
  backPortal.style.position = "absolute";
  backPortal.style.pointerEvents = "none";

  // Ön Katman (Kartın ve avatarın önünde duracak bölüm)
  const frontPortal = document.createElement("div");
  frontPortal.className = "duc-profile-effect-portal-front";
  frontPortal.style.position = "absolute";
  frontPortal.style.pointerEvents = "none";

  // MUCİZE BURADA: Arka portalı karttan ÖNCE, Ön portalı karttan SONRA ekliyoruz
  parent.insertBefore(backPortal, card);
  parent.insertBefore(frontPortal, card.nextSibling);

  const images = effect.layers
    .filter((layer) => layer && layer.image_url)
    .map((layer) => {
      const img = document.createElement("img");
      img.src = layer.image_url;
      img.alt = "";
      img.className = "duc-profile-effect-layer";
      img.style.position = "absolute";
      img.style.left = "0";
      img.style.width = "100%";
      img.style.height = "auto";
      img.style.display = "block";
      
      img.style[layer.anchor === "top" ? "top" : "bottom"] = "0";
      
      // Yönüne göre resmi ait olduğu portala atıyoruz
      if (layer.stack_order === "front") {
        frontPortal.appendChild(img);
      } else {
        backPortal.appendChild(img);
      }
      
      return img;
    });

  function layout() {
    if (!parent.contains(card)) return;

    // Kartın ebeveyne göre tam konumunu alıyoruz (Böylece scroll hatalarını sıfırlıyoruz)
    const width = card.offsetWidth;
    const height = card.offsetHeight;
    const left = card.offsetLeft;
    const top = card.offsetTop;

    const innerWidth = effect.effect_inner_width || effect.inner_width || 1200;
    const scale = width / innerWidth;
    
    const overflowH = (effect.effect_overflow_horizontal || effect.overflow_horizontal || 0) * scale;
    const overflowTop = (effect.effect_overflow_top || effect.overflow_top || 0) * scale;
    const overflowBottom = (effect.effect_overflow_bottom || effect.overflow_bottom || 0) * scale;

    const pLeft = `${left - overflowH}px`;
    const pTop = `${top - overflowTop}px`;
    const pWidth = `${width + overflowH * 2}px`;
    const pHeight = `${height + overflowTop + overflowBottom}px`;

    let cardZ = parseInt(getComputedStyle(card).zIndex, 10);
    if (!Number.isFinite(cardZ)) {
      cardZ = 1000;
      card.style.zIndex = cardZ;
    }

    // ARKA portal kartın arkasında durur
    backPortal.style.left = pLeft;
    backPortal.style.top = pTop;
    backPortal.style.width = pWidth;
    backPortal.style.height = pHeight;
    backPortal.style.zIndex = cardZ - 1;

    // ÖN portal kartın önünde durur
    frontPortal.style.left = pLeft;
    frontPortal.style.top = pTop;
    frontPortal.style.width = pWidth;
    frontPortal.style.height = pHeight;
    frontPortal.style.zIndex = cardZ + 1;
  }

  layout();

  let resizeObserver;
  if (typeof ResizeObserver !== "undefined") {
    resizeObserver = new ResizeObserver(layout);
    resizeObserver.observe(card);
  }

  return () => {
    resizeObserver?.disconnect();
    if (parent.contains(backPortal)) backPortal.remove();
    if (parent.contains(frontPortal)) frontPortal.remove();
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