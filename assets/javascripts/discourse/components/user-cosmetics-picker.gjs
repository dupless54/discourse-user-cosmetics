import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import DButton from "discourse/components/d-button";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { t } from "../lib/duc-i18n";

const KINDS = ["avatar_frame", "nameplate", "card_decoration", "profile_effect"];

export default class UserCosmeticsPicker extends Component {
  kinds = KINDS;

  @tracked activeKind = KINDS[0];
  @tracked items = null;
  @tracked active = null;
  @tracked loading = true;
  @tracked errorMessage = null;
  @tracked savingId = null;

  constructor() {
    super(...arguments);
    this.load();
  }

  @action
  async load() {
    this.loading = true;
    this.errorMessage = null;

    try {
      const response = await ajax("/user-cosmetics/mine.json");
      const decorated = {};

      KINDS.forEach((kind) => {
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
      rarityStyle: item.rarity_color ? `color: ${item.rarity_color};` : null,
      lockedTooltip: groupNamesLabel
        ? t("discourse_user_cosmetics.picker.locked_group_tooltip", {
            groups: groupNamesLabel,
          })
        : t("discourse_user_cosmetics.picker.locked_tooltip"),
    };
  }

  previewStyleFor(item) {
    if (item.image_url) {
      return `background-image: url("${item.image_url}");`;
    }

    if (item.gradient_from && item.gradient_to) {
      return `background-image: linear-gradient(135deg, ${item.gradient_from}, ${item.gradient_to});`;
    }

    return "";
  }

  get tabs() {
    return this.kinds.map((kind) => ({
      kind,
      label: t(`discourse_user_cosmetics.kinds.${kind}`),
      active: kind === this.activeKind,
    }));
  }

  get currentActiveId() {
    return this.active ? this.active[this.activeKind] : null;
  }

  get currentItems() {
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
    return t(`discourse_user_cosmetics.kinds.${this.activeKind}`);
  }

  get currentItemCountLabel() {
    return t("discourse_user_cosmetics.picker.item_count", {
      count: this.currentItems.length,
    });
  }

  @action
  setKind(kind, event) {
    this.activeKind = kind;
    event?.currentTarget?.scrollIntoView({
      behavior: "smooth",
      block: "nearest",
      inline: "nearest",
    });
  }

  @action
  async equip(item) {
    if (!item.owned || this.savingId) {
      return;
    }

    const kind = this.activeKind;
    const previous = this.active[kind];
    this.savingId = item.id;
    this.active = { ...this.active, [kind]: item.id };

    try {
      await ajax("/user-cosmetics/select.json", {
        type: "PUT",
        data: { kind, item_id: item.id },
      });
    } catch (e) {
      this.active = { ...this.active, [kind]: previous };
      popupAjaxError(e);
    } finally {
      this.savingId = null;
    }
  }

  @action
  async unequip() {
    const kind = this.activeKind;
    const previous = this.active ? this.active[kind] : null;

    if (!previous || this.savingId) {
      return;
    }

    this.savingId = previous;
    this.active = { ...this.active, [kind]: null };

    try {
      await ajax("/user-cosmetics/select.json", {
        type: "PUT",
        data: { kind, item_id: "" },
      });
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

      <div class="duc-cosmetics-page__body">
        {{#if this.loading}}
          <div class="duc-cosmetics-state"><div class="spinner"></div></div>
        {{else if this.errorMessage}}
          <div class="duc-cosmetics-state duc-cosmetics-state--error">
            <p>{{this.errorMessage}}</p>
            <DButton
              @icon="rotate"
              @action={{this.load}}
              @translatedLabel={{t "discourse_user_cosmetics.picker.title"}}
              class="btn-default"
            />
          </div>
        {{else}}
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
        {{/if}}
      </div>
    </section>
  </template>
}
