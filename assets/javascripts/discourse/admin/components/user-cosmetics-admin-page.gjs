import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { fn } from "@ember/helper";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DButton from "discourse/components/d-button";
import { t } from "../../lib/duc-i18n";
import UserCosmeticsAdminForm from "./user-cosmetics-admin-form";

const KINDS = ["avatar_frame", "nameplate", "card_decoration", "profile_effect"];

export default class UserCosmeticsAdminPage extends Component {
  kinds = KINDS;

  @tracked items = (this.args.model?.items ?? []).map((i) => this.decorateItem(i));
  @tracked groups = this.args.model?.groups ?? [];
  @tracked activeKind = KINDS[0];
  @tracked editingItem = null;
  @tracked isNew = false;

  decorateItem(item) {
    return {
      ...item,
      previewStyle: this.previewStyleFor(item),
      groupsLabel:
        item.group_names && item.group_names.length
          ? item.group_names.join(", ")
          : t("discourse_user_cosmetics.admin.everyone"),
    };
  }

  previewStyleFor(item) {
    if (item.image_url) {
      return `background-image: url("${item.image_url}");`;
    }
    if (item.gradient_from && item.gradient_to) {
      return `background-image: linear-gradient(135deg, ${item.gradient_from}, ${item.gradient_to});`;
    }
    const layerImage = (item.layers ?? []).find((l) => l.image_url)?.image_url;
    if (layerImage) {
      return `background-image: url("${layerImage}");`;
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

  get visibleItems() {
    return this.items.filter((i) => i.kind === this.activeKind);
  }

  @action
  setKind(kind) {
    this.activeKind = kind;
    this.editingItem = null;
  }

  @action
  startNew() {
    this.isNew = true;
    this.editingItem = {
      kind: this.activeKind,
      name: "",
      description: "",
      image_url: null,
      image_upload_id: null,
      raw_image_url: "",
      gradient_from: "",
      gradient_to: "",
      glow_color: "",
      rarity_label: "",
      rarity_color: "",
      sort_order: this.visibleItems.length,
      enabled: true,
      is_default: false,
      group_ids: [],
      effect_inner_width: 1200,
      effect_overflow_top: 300,
      effect_overflow_bottom: 140,
      effect_overflow_horizontal: 60,
      layers: [],
    };
  }

  @action
  startEdit(item) {
    this.isNew = false;
    this.editingItem = {
      ...item,
      group_ids: [...(item.group_ids ?? [])],
      layers: (item.layers ?? []).map((l) => ({ ...l })),
    };
  }

  @action
  cancelEdit() {
    this.editingItem = null;
  }

  @action
  afterSave(savedItem) {
    const decorated = this.decorateItem(savedItem);
    if (this.isNew) {
      this.items = [...this.items, decorated];
    } else {
      this.items = this.items.map((i) => (i.id === decorated.id ? decorated : i));
    }
    this.editingItem = null;
  }

  @action
  async deleteItem(item) {
    if (
      !window.confirm(
        t("discourse_user_cosmetics.admin.delete_confirm", { name: item.name })
      )
    ) {
      return;
    }
    try {
      await ajax(`/admin/plugins/user-cosmetics/items/${item.id}.json`, {
        type: "DELETE",
      });
      this.items = this.items.filter((i) => i.id !== item.id);
      if (this.editingItem?.id === item.id) {
        this.editingItem = null;
      }
    } catch (e) {
      popupAjaxError(e);
    }
  }

  <template>
    <div class="duc-admin-page">
      <h2>{{t "discourse_user_cosmetics.admin.title"}}</h2>
      <p class="duc-admin-intro">{{t "discourse_user_cosmetics.admin.intro"}}</p>

      <div class="duc-admin-tabs">
        {{#each this.tabs as |tab|}}
          <button
            type="button"
            class="duc-admin-tab {{if tab.active 'active'}}"
            {{on "click" (fn this.setKind tab.kind)}}
          >
            {{tab.label}}
          </button>
        {{/each}}
      </div>

      <div class="duc-admin-toolbar">
        <DButton
          @icon="plus"
          @translatedLabel={{t "discourse_user_cosmetics.admin.new_item"}}
          @action={{this.startNew}}
          class="btn-primary"
        />
      </div>

      {{#if this.editingItem}}
        <UserCosmeticsAdminForm
          @item={{this.editingItem}}
          @groups={{this.groups}}
          @isNew={{this.isNew}}
          @onCancel={{this.cancelEdit}}
          @onSaved={{this.afterSave}}
        />
      {{/if}}

      {{#if this.visibleItems.length}}
        <table class="duc-admin-table">
          <thead>
            <tr>
              <th>{{t "discourse_user_cosmetics.admin.table.preview"}}</th>
              <th>{{t "discourse_user_cosmetics.admin.table.name"}}</th>
              <th>{{t "discourse_user_cosmetics.admin.table.group"}}</th>
              <th>{{t "discourse_user_cosmetics.admin.table.owners"}}</th>
              <th>{{t "discourse_user_cosmetics.admin.table.enabled"}}</th>
              <th>{{t "discourse_user_cosmetics.admin.table.actions"}}</th>
            </tr>
          </thead>
          <tbody>
            {{#each this.visibleItems as |item|}}
              <tr>
                <td><div class="duc-admin-preview-swatch" style={{item.previewStyle}}></div></td>
                <td>
                  {{item.name}}
                  {{#if item.is_default}}
                    <span class="duc-admin-default-badge">{{t "discourse_user_cosmetics.admin.default_badge"}}</span>
                  {{/if}}
                </td>
                <td>{{item.groupsLabel}}</td>
                <td>{{item.owner_count}}</td>
                <td>{{if item.enabled "✓" "—"}}</td>
                <td class="duc-admin-row-actions">
                  <DButton @icon="pencil" @action={{fn this.startEdit item}} class="btn-small" />
                  <DButton @icon="trash-can" @action={{fn this.deleteItem item}} class="btn-small btn-danger" />
                </td>
              </tr>
            {{/each}}
          </tbody>
        </table>
      {{else}}
        <p class="duc-admin-empty">{{t "discourse_user_cosmetics.admin.no_items"}}</p>
      {{/if}}
    </div>
  </template>
}
