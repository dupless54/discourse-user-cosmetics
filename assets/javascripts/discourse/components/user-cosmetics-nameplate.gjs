import Component from "@glimmer/component";
import { get } from "@ember/object";
import { modifier } from "ember-modifier";

const CARD_SELECTOR = "#user-card, .user-card";
const CARD_TARGET_SELECTOR = ".name-username-wrapper";
const PROFILE_HOST_SELECTOR = ".user-main";
const PROFILE_TARGET_SELECTOR = ".user-profile-names__primary";
const TARGET_CLASS = "duc-nameplate-target";
const CARD_CLASS = "duc-nameplate-target--card";
const PROFILE_CLASS = "duc-nameplate-target--profile";

function backgroundImageFor(nameplate) {
  if (nameplate?.image_url) {
    return `url("${nameplate.image_url}")`;
  }

  if (nameplate?.gradient_from && nameplate?.gradient_to) {
    return `linear-gradient(90deg, ${nameplate.gradient_from}, ${nameplate.gradient_to})`;
  }

  return null;
}

function targetFor(element) {
  const directCardTarget = element.closest(CARD_TARGET_SELECTOR);
  if (directCardTarget) {
    return { element: directCardTarget, variant: CARD_CLASS };
  }

  const card = element.closest(CARD_SELECTOR);
  const cardTarget = card?.querySelector(CARD_TARGET_SELECTOR);
  if (cardTarget) {
    return { element: cardTarget, variant: CARD_CLASS };
  }

  const profile = element.closest(PROFILE_HOST_SELECTOR);
  const profileTarget = profile?.querySelector(PROFILE_TARGET_SELECTOR);
  if (profileTarget) {
    return { element: profileTarget, variant: PROFILE_CLASS };
  }

  return null;
}

const attachNameplate = modifier((element, [nameplate]) => {
  const backgroundImage = backgroundImageFor(nameplate);
  const target = targetFor(element);

  if (!backgroundImage || !target) {
    return;
  }

  const node = target.element;
  const original = {
    backgroundImage: node.style.backgroundImage,
    backgroundPosition: node.style.backgroundPosition,
    backgroundRepeat: node.style.backgroundRepeat,
    backgroundSize: node.style.backgroundSize,
  };

  node.classList.add(TARGET_CLASS, target.variant);
  node.style.backgroundImage = backgroundImage;
  node.style.backgroundPosition = "center";
  node.style.backgroundRepeat = "no-repeat";
  node.style.backgroundSize = "cover";

  return () => {
    node.classList.remove(TARGET_CLASS, target.variant);
    node.style.backgroundImage = original.backgroundImage;
    node.style.backgroundPosition = original.backgroundPosition;
    node.style.backgroundRepeat = original.backgroundRepeat;
    node.style.backgroundSize = original.backgroundSize;
  };
});

export default class UserCosmeticsNameplate extends Component {
  get user() {
    return (
      this.args.outletArgs?.user ??
      this.args.outletArgs?.model ??
      this.args.model
    );
  }

  get nameplate() {
    return get(this.user, "cosmetics")?.nameplate;
  }

  <template>
    {{#if this.nameplate}}
      <span
        class="duc-nameplate-anchor"
        aria-hidden="true"
        {{attachNameplate this.nameplate}}
      ></span>
    {{/if}}
  </template>
}
