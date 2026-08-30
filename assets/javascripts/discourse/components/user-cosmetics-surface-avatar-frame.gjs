import Component from "@glimmer/component";
import { get } from "@ember/object";
import { service } from "@ember/service";
import { modifier } from "ember-modifier";

const HOST_SELECTOR = ".user-card-avatar, .user-profile-avatar";
const HOST_CLASS = "duc-surface-avatar-frame";
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

const attachSurfaceFrame = modifier((element, [imageUrl, overhangPercent]) => {
  const host = element.closest(HOST_SELECTOR);
  if (!host || !imageUrl) {
    return;
  }

  const original = {
    image: host.style.getPropertyValue("--duc-surface-avatar-frame-image"),
    inset: host.style.getPropertyValue("--duc-surface-avatar-frame-inset"),
  };

  const inset = normalizedOverhangPercent(overhangPercent);
  host.classList.add(HOST_CLASS);
  host.style.setProperty(
    "--duc-surface-avatar-frame-image",
    `url("${escapeCssUrl(imageUrl)}")`
  );
  host.style.setProperty("--duc-surface-avatar-frame-inset", `-${inset}%`);

  return () => {
    host.classList.remove(HOST_CLASS);

    if (original.image) {
      host.style.setProperty("--duc-surface-avatar-frame-image", original.image);
    } else {
      host.style.removeProperty("--duc-surface-avatar-frame-image");
    }

    if (original.inset) {
      host.style.setProperty("--duc-surface-avatar-frame-inset", original.inset);
    } else {
      host.style.removeProperty("--duc-surface-avatar-frame-inset");
    }
  };
});

export default class UserCosmeticsSurfaceAvatarFrame extends Component {
  @service siteSettings;

  get user() {
    return (
      this.args.outletArgs?.user ??
      this.args.outletArgs?.model ??
      this.args.user
    );
  }

  get frame() {
    return get(this.user, "cosmetics")?.avatar_frame;
  }

  get overhangPercent() {
    return this.siteSettings.discourse_user_cosmetics_frame_overhang_percent;
  }

  <template>
    {{#if this.frame.image_url}}
      <span
        class="duc-surface-avatar-frame-anchor"
        aria-hidden="true"
        {{attachSurfaceFrame this.frame.image_url this.overhangPercent}}
      ></span>
    {{/if}}
  </template>
}
