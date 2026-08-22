import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { fn } from "@ember/helper";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DButton from "discourse/components/d-button";
import { t } from "../lib/duc-i18n";

const KINDS = ["avatar_frame", "nameplate", "card_decoration", "profile_effect"];

const LockIcon = <template>
  <svg
    viewBox="0 0 24 24"
    width="13"
    height="13"
    fill="currentColor"
    aria-hidden="true"
    class="duc-icon duc-icon-lock"
  ><path
      d="M12 1a5 5 0 0 0-5 5v3H6a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-9a2 2 0 0 0-2-2h-1V6a5 5 0 0 0-5-5zm-3 8V6a3 3 0 0 1 6 0v3H9zm3 4a2 2 0 0 1 1 3.73V19a1 1 0 1 1-2 0v-2.27A2 2 0 0 1 12 13z"
    ></path></svg>
</template>;

const CheckIcon = <template>
  <svg
    viewBox="0 0 24 24"
    width="15"
    height="15"
    fill="currentColor"
    aria-hidden="true"
    class="duc-icon duc-icon-check"
  ><path
      d="M9.55 17.6 4.4 12.45l1.41-1.41 3.74 3.73 8.64-8.64 1.41 1.41z"
    ></path></svg>
</template>;

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

  @action
  setKind(kind) {
    this.activeKind = kind;
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

  @action
  close() {
    this.args.onClose?.();
  }

  @action
  stopPropagation(event) {
    event.stopPropagation();
  }

  <template>
    <div class="duc-picker-overlay" {{on "click" this.close}}>
      <div class="duc-picker-dialog" {{on "click" this.stopPropagation}}>
        <div class="duc-picker-header">
          <h3>{{t "discourse_user_cosmetics.picker.title"}}</h3>
          <DButton
            @icon="xmark"
            @action={{this.close}}
            class="btn-flat duc-picker-close"
          />
        </div>

        <div class="duc-picker-tabs">
          {{#each this.tabs as |tab|}}
            <button
              type="button"
              class="duc-picker-tab {{if tab.active 'active'}}"
              {{on "click" (fn this.setKind tab.kind)}}
            >
              {{tab.label}}
            </button>
          {{/each}}
        </div>

        <div class="duc-picker-body">
          {{#if this.loading}}
            <div class="duc-picker-loading"><div class="spinner"></div></div>
          {{else if this.errorMessage}}
            <p class="duc-picker-error">{{this.errorMessage}}</p>
          {{else}}
            {{#if this.hasActiveSelection}}
              <div class="duc-picker-current-actions">
                <DButton
                  @icon="xmark"
                  @translatedLabel={{t "discourse_user_cosmetics.picker.remove"}}
                  @action={{this.unequip}}
                  class="btn-default btn-small duc-unequip-btn"
                />
              </div>
            {{/if}}

            {{#if this.currentItems.length}}
              <div class="duc-picker-grid">
                {{#each this.currentItems as |item|}}
                  <div
                    class="duc-picker-tile
                      {{if item.owned 'owned' 'locked'}}
                      {{if item.isActive 'active'}}"
                  >
                    <div class="duc-picker-tile-preview" style={{item.previewStyle}}>
                      {{#unless item.owned}}
                        <span class="duc-picker-tile-lock"><LockIcon /></span>
                      {{/unless}}
                      {{#if item.isActive}}
                        <span class="duc-picker-tile-check"><CheckIcon /></span>
                      {{/if}}
                    </div>

                    <div class="duc-picker-tile-name">{{item.name}}</div>

                    {{#if item.rarity_label}}
                      <div class="duc-picker-tile-rarity" style={{item.rarityStyle}}>
                        {{item.rarity_label}}
                      </div>
                    {{/if}}

                    {{#if item.owned}}
                      <DButton
                        @translatedLabel={{item.actionLabel}}
                        @disabled={{item.isActive}}
                        @action={{fn this.equip item}}
                        class="btn-small duc-equip-btn"
                      />
                    {{else}}
                      <span class="duc-picker-tile-locked-label" title={{item.lockedTooltip}}>
                        <LockIcon />
                        {{t "discourse_user_cosmetics.picker.locked"}}
                      </span>
                    {{/if}}
                  </div>
                {{/each}}
              </div>
            {{else}}
              <p class="duc-picker-empty">{{t "discourse_user_cosmetics.picker.none_for_kind"}}</p>
            {{/if}}
          {{/if}}
        </div>
      </div>
    </div>
  </template>
}
