import Component from "@glimmer/component";
import { get } from "@ember/object";
import { modifier } from "ember-modifier";
import { prefersReducedMotion } from "../lib/duc-motion";

const CARD_SELECTOR = "#user-card, .user-card";
const HOST_CLASS = "duc-profile-effect-host";
const CARD_CLASS = "duc-profile-effect-card";

const attachProfileEffect = modifier((element, [effect]) => {
  const card = element.closest(CARD_SELECTOR);

  if (
    prefersReducedMotion() ||
    !card ||
    !effect ||
    !Array.isArray(effect.layers) ||
    effect.layers.length === 0
  ) {
    return;
  }

  const parent = card.parentElement;
  if (!parent) {
    return;
  }

  const originalInlinePosition = parent.style.position;
  const needsPositionContext = getComputedStyle(parent).position === "static";

  if (needsPositionContext) {
    parent.style.position = "relative";
  }

  parent.classList.add(HOST_CLASS);
  card.classList.add(CARD_CLASS);

  const backPortal = document.createElement("div");
  backPortal.className =
    "duc-profile-effect-portal duc-profile-effect-portal--back";

  const frontPortal = document.createElement("div");
  frontPortal.className =
    "duc-profile-effect-portal duc-profile-effect-portal--front";

  parent.insertBefore(backPortal, card);
  parent.insertBefore(frontPortal, card.nextSibling);

  const images = effect.layers
    .filter((layer) => layer && layer.image_url)
    .map((layer) => {
      const img = document.createElement("img");
      img.src = layer.image_url;
      img.alt = "";
      img.setAttribute("aria-hidden", "true");
      img.className = "duc-profile-effect-layer";
      img.dataset.anchor = layer.anchor;
      img.dataset.stackOrder = layer.stack_order;

      if (layer.anchor === "full") {
        img.style.top = "0";
        img.style.left = "0";
        img.style.width = "100%";
        img.style.height = "100%";
      } else if (layer.anchor === "left" || layer.anchor === "right") {
        img.style.top = "var(--duc-side-offset-top, 0px)";
        img.style.height =
          "calc(100% - var(--duc-side-offset-top, 0px) - var(--duc-side-offset-bottom, 0px))";
        img.style.width = "auto";
        img.style[layer.anchor] = "0";
      } else {
        img.style.left = "0";
        img.style.width = "100%";
        img.style.height = "auto";
        img.style[layer.anchor === "top" ? "top" : "bottom"] = "0";
      }

      if (layer.stack_order === "front") {
        frontPortal.appendChild(img);
      } else {
        backPortal.appendChild(img);
      }

      return img;
    });

  function layout() {
    if (!parent.contains(card)) {
      return;
    }

    const width = card.offsetWidth;
    const height = card.offsetHeight;
    const left = card.offsetLeft;
    const top = card.offsetTop;

    const innerWidth = effect.effect_inner_width || effect.inner_width || 1200;
    const scale = width / innerWidth;

    const overflowH =
      (effect.effect_overflow_horizontal || effect.overflow_horizontal || 0) *
      scale;
    const overflowTop =
      (effect.effect_overflow_top || effect.overflow_top || 0) * scale;
    const overflowBottom =
      (effect.effect_overflow_bottom || effect.overflow_bottom || 0) * scale;
    const sideOffsetTop = (effect.effect_side_offset_top || 0) * scale;
    const sideOffsetBottom = (effect.effect_side_offset_bottom || 0) * scale;

    const portalLeft = `${left - overflowH}px`;
    const portalTop = `${top - overflowTop}px`;
    const portalWidth = `${width + overflowH * 2}px`;
    const portalHeight = `${height + overflowTop + overflowBottom}px`;

    const applyPortalStyles = (portal) => {
      portal.style.left = portalLeft;
      portal.style.top = portalTop;
      portal.style.width = portalWidth;
      portal.style.height = portalHeight;
      portal.style.setProperty("--duc-side-offset-top", `${sideOffsetTop}px`);
      portal.style.setProperty(
        "--duc-side-offset-bottom",
        `${sideOffsetBottom}px`
      );
    };

    applyPortalStyles(backPortal);
    applyPortalStyles(frontPortal);
  }

  layout();

  let resizeObserver;
  if (typeof ResizeObserver !== "undefined") {
    resizeObserver = new ResizeObserver(layout);
    resizeObserver.observe(card);
  }

  return () => {
    resizeObserver?.disconnect();
    backPortal.remove();
    frontPortal.remove();
    parent.classList.remove(HOST_CLASS);
    card.classList.remove(CARD_CLASS);

    if (needsPositionContext) {
      parent.style.position = originalInlinePosition;
    }
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
    return get(this.user, "cosmetics")?.profile_effect;
  }

  <template>
    {{#if this.effect}}
      <div class="duc-profile-effect-anchor" {{attachProfileEffect this.effect}}></div>
    {{/if}}
  </template>
}
