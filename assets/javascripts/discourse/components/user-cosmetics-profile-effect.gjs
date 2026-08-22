import Component from "@glimmer/component";
import { modifier } from "ember-modifier";
import { htmlSafe } from "@ember/template";

const PORTAL_CLASS = "duc-profile-effect-portal";

// HATA 1'İN ÇÖZÜMÜ: .user-profile ve .user-main'i sildik! 
// Artık devasa canavar yok, sadece küçük kullanıcı kartına (user-card) odaklanıyoruz.
const CARD_SELECTOR = "#user-card, .user-card"; 

const attachProfileEffect = modifier((element, [effect]) => {
  const card = element.closest(CARD_SELECTOR);

  if (!card || !effect || !Array.isArray(effect.layers) || effect.layers.length === 0) {
    return;
  }

  // HATA 2'NİN ÇÖZÜMÜ: Kartı izole ediyoruz (3D Derinlik için)
  card.style.isolation = "isolate";
  card.style.overflow = "visible";
  if (getComputedStyle(card).position === "static") {
    card.style.position = "relative";
  }

  const portal = document.createElement("div");
  portal.className = PORTAL_CLASS;
  portal.style.position = "absolute";
  portal.style.pointerEvents = "none";
  
  // Efekti sayfanın dibine (body) DEĞİL, doğrudan kartın içine ekliyoruz!
  card.appendChild(portal);

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
      
      // DERİNLİK HİSSİYATI: Ön katmanlar 10, Arka katmanlar -1
      // İzolasyon sayesinde -1 olanlar kartın arka planının içine gömülecek
      img.style.zIndex = layer.stack_order === "front" ? "10" : "-1";
      
      portal.appendChild(img);
      return img;
    });

  function layout() {
    if (!card.contains(portal)) {
      return;
    }

    const rect = card.getBoundingClientRect();
    const innerWidth = effect.effect_inner_width || effect.inner_width || 1200;
    const scale = rect.width / innerWidth;
    
    const overflowH = (effect.effect_overflow_horizontal || effect.overflow_horizontal || 0) * scale;
    const overflowTop = (effect.effect_overflow_top || effect.overflow_top || 0) * scale;
    const overflowBottom = (effect.effect_overflow_bottom || effect.overflow_bottom || 0) * scale;

    // Portal kartın içinde olduğu için, ekran koordinatları (scrollX) hesaplamaya 
    // gerek kalmadı. Sadece negatif paylar (margin) vererek dışarı taşırıyoruz.
    portal.style.left = `-${overflowH}px`;
    portal.style.top = `-${overflowTop}px`;
    portal.style.width = `calc(100% + ${overflowH * 2}px)`;
    portal.style.height = `calc(100% + ${overflowTop + overflowBottom}px)`;
  }

  layout();

  let resizeObserver;
  if (typeof ResizeObserver !== "undefined") {
    resizeObserver = new ResizeObserver(layout);
    resizeObserver.observe(card);
  }

  return () => {
    resizeObserver?.disconnect();
    if (card.contains(portal)) {
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
        isolation: isolate !important;
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