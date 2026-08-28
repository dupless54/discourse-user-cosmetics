import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
import { trustHTML } from "@ember/template";
import DButton from "discourse/components/d-button";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { enabledCosmeticKinds } from "../lib/duc-cosmetic-kinds";
import {
  refreshCosmeticsStylesheet,
  syncCurrentUserAvatarFrame,
} from "../lib/duc-current-user-presentation";
import { t } from "../lib/duc-i18n";

const HEX_COLOR_REGEX = /^#[0-9a-fA-F]{3}(?:[0-9a-fA-F]{3}(?:[0-9a-fA-F]{2})?)?$/;
const STYLESHEET_KINDS = ["avatar_frame", "nameplate"];

function safeHexColor(value) {
  return typeof value === "string" && HEX_COLOR_REGEX.test(value) ? value : null;
}

function safeColorStyle(property, value) {
  const color = safeHexColor(value);
  return color ? trustHTML(`${property}: ${color};`) : null;
}

export default class UserCosmeticsPicker extends Component {
  @service currentUser;
  @service siteSettings;

  @tracked activeKind = null;
  @tracked items = null;
  @tracked active = null;
  @tracked loading = true;
  @tracked errorMessage = null;
  @tracked savingId = null;

  constructor() {
    super(...arguments);
    this.activeKind = this.kinds[0] ?? null;
    this.load();
  }

  get kinds() {
    return enabledCosmeticKinds(this.siteSettings);
  }

  @action
  async load() {
    this.loading = true;
    this.errorMessage = null;

    const kinds = this.kinds;

    if (!kinds.length) {
      this.items = {};
      this.active = {};
      this.loading = false;
      return;
    }

    try {
      const response = await ajax("/user-cosmetics/mine.json");
      const decorated = {};

      kinds.forEach((kind) => {
        decorated[kind] = (response.items?.[kind] ?? []).map((item) =>
          this.decorate(item)
        );
      });

      this.items = decorated;
      this.active = response.active ?? {};
    } catch (e) {
      this.errorMessage = t("discourse_user_cosmetics.picker.save_error");
    } finally {
      this.loading = false;
    }
  }

  decorate(item) {
    const groupNamesLabel =
      item.group_names && item.group_names.length
        ? item.group_names.join(", ")
        : null;

    return {
      ...item,
      previewStyle: this.previewStyleFor(item),
      rarityStyle: safeColorStyle("color", item.rarity_color),
      lockedTooltip: groupNamesLabel
        ? t("discourse_user_cosmetics.picker.locked_group_tooltip", {
            groups: groupNamesLabel,
          })
        : t("discourse_user_cosmetics.picker.locked_tooltip"),
    };
  }

  previewStyleFor(item) {
    const from = safeHexColor(item.gradient_from);
    const to = safeHexColor(item.gradient_to);

    if (from && to) {
      return trustHTML(
        `background-image: linear-gradient(135deg, ${from}, ${to});`
      );
    }

    return null;
  }

  get tabs() {
    return this.kinds.map((kind) => ({
      kind,
      label: t(`discourse_user_cosmetics.kinds.${kind}`),
      active: kind === this.activeKind,
    }));
  }

  get currentActiveId() {
    return this.activeKind && this.active ? this.active[this.activeKind] : null;
  }

  get currentItems() {
    if (!this.activeKind) {
      return [];
    }

    const list = this.items?.[this.activeKind] ?? [];
    const activeId = this.currentActiveId;

    return list.map((item) => {
      const isActive = activeId != null && Number(activeId) === Number(item.id);

      return {
        ...item,
        isActive,
        actionLabel: isActive
          ? t("discourse_user_cosmetics.picker.equipped")
          : t("discourse_user_cosmetics.picker.equip"),
      };
    });
  }

  get hasActiveSelection() {
    return this.currentActiveId != null;
  }

  get currentKindLabel() {
    return this.activeKind
      ? t(`discourse_user_cosmetics.kinds.${this.activeKind}`)
      : "";
  }

  get currentItemCountLabel() {
    return t("discourse_user_cosmetics.picker.item_count", {
      count: this.currentItems.length,
    });
  }

  applySelectionResponse(response, kind) {
    const cosmetics = response?.cosmetics;
    if (!cosmetics || !this.currentUser) {
      return;
    }

    this.currentUser.set("cosmetics", cosmetics);
    syncCurrentUserAvatarFrame(
      cosmetics.avatar_frame,
      this.siteSettings.discourse_user_cosmetics_frame_overhang_percent
    );

    if (STYLESHEET_KINDS.includes(kind)) {
      refreshCosmeticsStylesheet();
    }
  }

  @action
  setKind(kind, event) {
    if (!this.kinds.includes(kind)) {
      return;
    }

    this.activeKind = kind;
    event?.currentTarget?.scrollIntoView({
      behavior: "smooth",
      block: "nearest",
      inline: "nearest",
    });
  }

  @action
  async equip(item) {
    if (!this.activeKind || !item.owned || this.savingId) {
      return;
    }

    const kind = this.activeKind;
    const previous = this.active[kind];
    this.savingId = item.id;
    this.active = { ...this.active, [kind]: item.id };

    try {
      const response = await ajax("/user-cosmetics/select.json", {
        type: "PUT",
        data: { kind, item_id: item.id },
      });
      this.applySelectionResponse(response, kind);
    } catch (e) {
      this.active = { ...this.active, [kind]: previous };
      popupAjaxError(e);
    } finally {
      this.savingId = null;
    }
  }

  @action
  async unequip() {
    if (!this.activeKind) {
      return;
    }

    const kind = this.activeKind;
    const previous = this.active ? this.active[kind] : null;

    if (!previous || this.savingId) {
      return;
    }

    this.savingId = previous;
    this.active = { ...this.active, [kind]: null };

    try {
      const response = await ajax("/user-cosmetics/select.json", {
        type: "PUT",
        data: { kind, item_id: "" },
      });
      this.applySelectionResponse(response, kind);
    } catch (e) {
      this.active = { ...this.active, [kind]: previous };
      popupAjaxError(e);
    } finally {
      this.savingId = null;
    }
  }

  <template>
    <section class="duc-cosmetics-page">
      <header class="duc-cosmetics-page__header">
        <h2>{{t "discourse_user_cosmetics.preferences.title"}}</h2>
        <p>{{t "discourse_user_cosmetics.picker.subtitle"}}</p>
      </header>

      {{#if this.activeKind}}
        <div
          class="duc-cosmetics-tabs"
          role="tablist"
          aria-label={{t "discourse_user_cosmetics.preferences.title"}}
        >
          {{#each this.tabs as |tab|}}
            <button
              type="button"
              role="tab"
              aria-selected={{if tab.active "true" "false"}}
              class="duc-cosmetics-tab {{if tab.active 'active'}}"
              {{on "click" (fn this.setKind tab.kind)}}
            >
              {{tab.label}}
            </button>
          {{/each}}
        </div>
      {{/if}}

      <div class="duc-cosmetics-page__body">
        {{#if this.loading}}
          <div class="duc-cosmetics-state"><div class="spinner"></div></div>
        {{else if this.errorMessage}}
          <div class="duc-cosmetics-state duc-cosmetics-state--error">
            <p>{{this.errorMessage}}</p>
            <DButton
              @icon="rotate"
              @action={{this.load}}
              @translatedLabel={{t "discourse_user_cosmetics.picker.retry"}}
              class="btn-default"
            />
          </div>
        {{else if this.activeKind}}
          <div class="duc-cosmetics-section-heading">
            <div>
              <h3>{{this.currentKindLabel}}</h3>
              <p>{{this.currentItemCountLabel}}</p>
            </div>

            {{#if this.hasActiveSelection}}
              <DButton
                @icon="xmark"
                @translatedLabel={{t "discourse_user_cosmetics.picker.remove"}}
                @action={{this.unequip}}
                class="btn-default btn-small"
              />
            {{/if}}
          </div>

          {{#if this.currentItems.length}}
            <div class="duc-cosmetics-grid">
              {{#each this.currentItems as |item|}}
                <article
                  class="duc-cosmetics-item
                    {{if item.owned 'owned' 'locked'}}
                    {{if item.isActive 'active'}}"
                >
                  <div
                    class="duc-cosmetics-item__preview
                      duc-cosmetics-item__preview--{{this.activeKind}}"
                    style={{item.previewStyle}}
                  >
                    {{#if item.image_url}}
                      <img
                        class="duc-cosmetics-item__preview-image"
                        src={{item.image_url}}
                        alt=""
                      />
                    {{/if}}

                    {{#unless item.owned}}
                      <span class="duc-cosmetics-item__lock" title={{item.lockedTooltip}}>
                        {{dIcon "lock"}}
                      </span>
                    {{/unless}}

                    {{#if item.isActive}}
                      <span class="duc-cosmetics-item__check" aria-hidden="true">
                        {{dIcon "check"}}
                      </span>
                    {{/if}}
                  </div>

                  <div class="duc-cosmetics-item__content">
                    <div class="duc-cosmetics-item__name">{{item.name}}</div>

                    {{#if item.description}}
                      <p class="duc-cosmetics-item__description">{{item.description}}</p>
                    {{/if}}

                    {{#if item.rarity_label}}
                      <div class="duc-cosmetics-item__rarity" style={{item.rarityStyle}}>
                        {{item.rarity_label}}
                      </div>
                    {{/if}}
                  </div>

                  <div class="duc-cosmetics-item__actions">
                    {{#if item.owned}}
                      <DButton
                        @translatedLabel={{item.actionLabel}}
                        @disabled={{item.isActive}}
                        @action={{fn this.equip item}}
                        class={{if item.isActive "btn-primary btn-small" "btn-default btn-small"}}
                      />
                    {{else}}
                      <span class="duc-cosmetics-item__locked-label" title={{item.lockedTooltip}}>
                        {{dIcon "lock"}}
                        {{t "discourse_user_cosmetics.picker.locked"}}
                      </span>
                    {{/if}}
                  </div>
                </article>
              {{/each}}
            </div>
          {{else}}
            <p class="duc-cosmetics-empty">
              {{t "discourse_user_cosmetics.picker.none_for_kind"}}
            </p>
          {{/if}}
        {{else}}
          <p class="duc-cosmetics-empty">
            {{t "discourse_user_cosmetics.picker.none_enabled"}}
          </p>
        {{/if}}
      </div>
    </section>
  </template>
}
