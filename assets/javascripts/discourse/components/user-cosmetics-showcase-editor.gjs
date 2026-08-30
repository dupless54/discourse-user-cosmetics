import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DButton from "discourse/ui-kit/d-button";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

export default class UserCosmeticsShowcaseEditor extends Component {
  @tracked items = [];
  @tracked selectedIds = [];
  @tracked savedIds = [];
  @tracked limit = 6;
  @tracked loading = true;
  @tracked saving = false;

  constructor() {
    super(...arguments);
    this.load();
  }

  get selectedItems() {
    const byId = new Map(this.items.map((item) => [Number(item.id), item]));
    const lastIndex = this.selectedIds.length - 1;

    return this.selectedIds
      .map((id, index) => {
        const item = byId.get(Number(id));
        if (!item) {
          return null;
        }

        return {
          ...item,
          position: index + 1,
          movePreviousDisabled: index === 0,
          moveNextDisabled: index === lastIndex,
        };
      })
      .filter(Boolean);
  }

  get availableItems() {
    const selected = new Set(this.selectedIds.map(Number));
    return this.items.filter((item) => !selected.has(Number(item.id)));
  }

  get atLimit() {
    return this.selectedIds.length >= this.limit;
  }

  get dirty() {
    return JSON.stringify(this.selectedIds) !== JSON.stringify(this.savedIds);
  }

  get saveDisabled() {
    return this.saving || !this.dirty;
  }

  get countLabel() {
    return i18n("discourse_user_cosmetics.showcase.editor_count", {
      count: this.selectedIds.length,
      limit: this.limit,
    });
  }

  @action
  async load() {
    this.loading = true;

    try {
      const response = await ajax("/user-cosmetics/mine.json");
      const seen = new Set();
      const owned = [];

      Object.values(response.items ?? {}).forEach((rows) => {
        (rows ?? []).forEach((item) => {
          const id = Number(item.id);
          if (!item.owned || seen.has(id)) {
            return;
          }

          seen.add(id);
          owned.push(item);
        });
      });

      const ids = (response.showcase_item_ids ?? []).map(Number);
      this.items = owned;
      this.limit = Number(response.showcase_limit) || 6;
      this.selectedIds = ids;
      this.savedIds = [...ids];
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.loading = false;
    }
  }

  @action
  add(itemId) {
    const id = Number(itemId);
    if (this.atLimit || this.selectedIds.includes(id)) {
      return;
    }

    this.selectedIds = [...this.selectedIds, id];
  }

  @action
  remove(itemId) {
    const id = Number(itemId);
    this.selectedIds = this.selectedIds.filter((candidate) => candidate !== id);
  }

  @action
  move(itemId, delta) {
    const id = Number(itemId);
    const sourceIndex = this.selectedIds.indexOf(id);
    const targetIndex = sourceIndex + Number(delta);

    if (
      sourceIndex < 0 ||
      targetIndex < 0 ||
      targetIndex >= this.selectedIds.length
    ) {
      return;
    }

    const next = [...this.selectedIds];
    [next[sourceIndex], next[targetIndex]] = [
      next[targetIndex],
      next[sourceIndex],
    ];
    this.selectedIds = next;
  }

  @action
  async save() {
    if (this.saveDisabled) {
      return;
    }

    this.saving = true;

    try {
      await ajax("/user-cosmetics/showcase.json", {
        type: "PUT",
        data: { item_ids: this.selectedIds },
      });
      this.savedIds = [...this.selectedIds];
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.saving = false;
    }
  }

  <template>
    <section class="duc-showcase-editor" aria-busy={{if this.loading "true" "false"}}>
      <header class="duc-showcase-editor__header">
        <div>
          <h3>{{i18n "discourse_user_cosmetics.showcase.editor_title"}}</h3>
          <p>{{i18n "discourse_user_cosmetics.showcase.editor_subtitle"}}</p>
        </div>
        <span class="duc-showcase-editor__count">{{this.countLabel}}</span>
      </header>

      {{#if this.loading}}
        <div class="duc-showcase-editor__loading" role="status">
          <div class="spinner" aria-hidden="true"></div>
          <span class="sr-only">{{i18n "loading"}}</span>
        </div>
      {{else}}
        <div class="duc-showcase-editor__selected">
          <h4>{{i18n "discourse_user_cosmetics.showcase.selected_title"}}</h4>

          {{#if this.selectedItems.length}}
            <div class="duc-showcase-editor__selected-grid">
              {{#each this.selectedItems as |item|}}
                <article class="duc-showcase-editor__selected-item">
                  <span class="duc-showcase-editor__position">{{item.position}}</span>
                  <div class="duc-showcase-editor__preview">
                    {{#if item.image_url}}
                      <img src={{item.image_url}} alt="" />
                    {{/if}}
                  </div>
                  <strong title={{item.name}}>{{item.name}}</strong>

                  <div class="duc-showcase-editor__item-actions">
                    <DButton
                      @icon="chevron-left"
                      @translatedTitle={{i18n "discourse_user_cosmetics.showcase.move_previous"}}
                      @translatedAriaLabel={{i18n "discourse_user_cosmetics.showcase.move_previous"}}
                      @disabled={{item.movePreviousDisabled}}
                      @action={{fn this.move item.id -1}}
                      class="btn-flat btn-small"
                    />
                    <DButton
                      @icon="chevron-right"
                      @translatedTitle={{i18n "discourse_user_cosmetics.showcase.move_next"}}
                      @translatedAriaLabel={{i18n "discourse_user_cosmetics.showcase.move_next"}}
                      @disabled={{item.moveNextDisabled}}
                      @action={{fn this.move item.id 1}}
                      class="btn-flat btn-small"
                    />
                    <DButton
                      @icon="xmark"
                      @translatedTitle={{i18n "discourse_user_cosmetics.showcase.remove"}}
                      @translatedAriaLabel={{i18n "discourse_user_cosmetics.showcase.remove"}}
                      @action={{fn this.remove item.id}}
                      class="btn-flat btn-small"
                    />
                  </div>
                </article>
              {{/each}}
            </div>
          {{else}}
            <p class="duc-showcase-editor__empty">{{i18n "discourse_user_cosmetics.showcase.selected_empty"}}</p>
          {{/if}}
        </div>

        <div class="duc-showcase-editor__available">
          <div class="duc-showcase-editor__section-heading">
            <h4>{{i18n "discourse_user_cosmetics.showcase.available_title"}}</h4>
            {{#if this.atLimit}}
              <span>{{i18n "discourse_user_cosmetics.showcase.limit_reached"}}</span>
            {{/if}}
          </div>

          {{#if this.availableItems.length}}
            <div class="duc-showcase-editor__available-grid">
              {{#each this.availableItems as |item|}}
                <button
                  type="button"
                  class="duc-showcase-editor__available-item"
                  disabled={{this.atLimit}}
                  {{on "click" (fn this.add item.id)}}
                >
                  <span class="duc-showcase-editor__preview">
                    {{#if item.image_url}}
                      <img src={{item.image_url}} alt="" />
                    {{/if}}
                  </span>
                  <span class="duc-showcase-editor__available-meta">
                    <strong>{{item.name}}</strong>
                    {{#if item.rarity_label}}<small>{{item.rarity_label}}</small>{{/if}}
                  </span>
                  {{dIcon "plus"}}
                </button>
              {{/each}}
            </div>
          {{else}}
            <p class="duc-showcase-editor__empty">{{i18n "discourse_user_cosmetics.showcase.available_empty"}}</p>
          {{/if}}
        </div>

        <div class="duc-showcase-editor__footer">
          <DButton
            @action={{this.save}}
            @disabled={{this.saveDisabled}}
            @isLoading={{this.saving}}
            @translatedLabel={{i18n "discourse_user_cosmetics.showcase.save"}}
            class="btn-primary"
          />
          {{#unless this.dirty}}
            <span>{{i18n "discourse_user_cosmetics.showcase.saved"}}</span>
          {{/unless}}
        </div>
      {{/if}}
    </section>
  </template>
}
