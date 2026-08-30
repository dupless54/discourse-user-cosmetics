import Component from "@glimmer/component";
import { get } from "@ember/object";
import { service } from "@ember/service";
import { modifier } from "ember-modifier";

const HOST_SELECTOR = "#current-user";
const HOST_CLASS = "duc-current-user-frame";
const DEFAULT_OVERHANG_PERCENT = 14;
const MIN_OVERHANG_PERCENT = 0;
const MAX_OVERHANG_PERCENT = 60;

function normalizedOverhangPercent(value) {
  const parsed = Number.parseInt(value, 10);
  const percent = Number.isFinite(parsed) ? parsed : DEFAULT_OVERHANG_PERCENT;

  return Math.min(
    MAX_OVERHANG_PERCENT,
    Math.max(MIN_OVERHANG_PERCENT, percent)
  );
}

function escapeCssUrl(value) {
  return String(value)
    .replace(/\\/g, "\\\\")
    .replace(/"/g, '\\"')
    .replace(/[\n\r\f]/g, "");
}

const attachHeaderFrame = modifier((element, [imageUrl, overhangPercent]) => {
  const host = element.closest(HOST_SELECTOR);
  if (!host || !imageUrl) {
    return;
  }

  const original = {
    image: host.style.getPropertyValue("--duc-current-user-frame-image"),
    inset: host.style.getPropertyValue("--duc-current-user-frame-inset"),
  };

  const inset = normalizedOverhangPercent(overhangPercent);
  host.classList.add(HOST_CLASS);
  host.style.setProperty(
    "--duc-current-user-frame-image",
    `url("${escapeCssUrl(imageUrl)}")`
  );
  host.style.setProperty("--duc-current-user-frame-inset", `-${inset}%`);

  return () => {
    host.classList.remove(HOST_CLASS);

    if (original.image) {
      host.style.setProperty("--duc-current-user-frame-image", original.image);
    } else {
      host.style.removeProperty("--duc-current-user-frame-image");
    }

    if (original.inset) {
      host.style.setProperty("--duc-current-user-frame-inset", original.inset);
    } else {
      host.style.removeProperty("--duc-current-user-frame-inset");
    }
  };
});

export default class UserCosmeticsHeaderFrame extends Component {
  @service currentUser;
  @service siteSettings;

  get frame() {
    return get(this.currentUser, "cosmetics")?.avatar_frame;
  }

  get overhangPercent() {
    return this.siteSettings.discourse_user_cosmetics_frame_overhang_percent;
  }

  <template>
    {{#if this.frame.image_url}}
      <span
        class="duc-current-user-frame-anchor"
        aria-hidden="true"
        {{attachHeaderFrame this.frame.image_url this.overhangPercent}}
      ></span>
    {{/if}}
  </template>
}
