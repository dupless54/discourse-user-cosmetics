import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { on } from "@ember/modifier";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";
import UserCosmeticsAdminForm from "./user-cosmetics-admin-form";
import UserCosmeticsDeleteItemModal from "./modal/user-cosmetics-delete-item";

const KINDS = [
  "avatar_frame",
  "nameplate",
  "card_decoration",
  "profile_effect",
];

export default class UserCosmeticsAdminPage extends Component {
  @service modal;

  kinds = KINDS;

  @tracked items = (this.args.model?.items ?? []).map((item) =>
    this.decorateItem(item)
  );
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
          : i18n("discourse_user_cosmetics.admin.everyone"),
    };
  }

  previewStyleFor(item) {
    if (item.image_url) {
      return `background-image: url("${item.image_url}");`;
    }
    if (item.gradient_from && item.gradient_to) {
      return `background-image: linear-gradient(135deg, ${item.gradient_from}, ${item.gradient_to});`;
    }
    const layerImage = (item.layers ?? []).find(
      (layer) => layer.image_url
    )?.image_url;
    if (layerImage) {
      return `background-image: url("${layerImage}");`;
    }
    return "";
  }

  get tabs() {
    return this.kinds.map((kind) => ({
      kind,
      label: i18n(`discourse_user_cosmetics.kinds.${kind}`),
      count: this.items.filter((item) => item.kind === kind).length,
      active: kind === this.activeKind,
    }));
  }

  get visibleItems() {
    return this.items.filter((item) => item.kind === this.activeKind);
  }

  @action
  setKind(kind, event) {
    if (!this.kinds.includes(kind)) {
      return;
    }

    this.activeKind = kind;
    this.editingItem = null;
    event?.currentTarget?.scrollIntoView({
      behavior: "smooth",
      block: "nearest",
      inline: "nearest",
    });
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
      effect_side_offset_top: 0,
      effect_side_offset_bottom: 0,
      layers: [],
    };
  }

  @action
  startEdit(item) {
    this.isNew = false;
    this.editingItem = {
      ...item,
      group_ids: [...(item.group_ids ?? [])],
      layers: (item.layers ?? []).map((layer) => ({ ...layer })),
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
      this.items = this.items.map((item) =>
        item.id === decorated.id ? decorated : item
      );
    }
    this.editingItem = null;
  }

  @action
  afterDelete(item) {
    this.items = this.items.filter((existing) => existing.id !== item.id);
    if (this.editingItem?.id === item.id) {
      this.editingItem = null;
    }
  }

  @action
  deleteItem(item) {
    return this.modal.show(UserCosmeticsDeleteItemModal, {
      model: {
        item,
        onDeleted: this.afterDelete,
      },
    });
  }

  <template>
    <div class="duc-admin-page">
      <div class="duc-admin-header">
        <div class="duc-admin-heading">
          <h2>{{i18n "discourse_user_cosmetics.admin.title"}}</h2>
          <p class="duc-admin-intro">{{i18n
              "discourse_user_cosmetics.admin.intro"
            }}</p>
        </div>

        <DButton
          @icon="plus"
          @translatedLabel={{i18n "discourse_user_cosmetics.admin.new_item"}}
          @action={{this.startNew}}
          class="btn-primary duc-admin-new-item"
        />
      </div>

      <section class="admin-controls duc-admin-controls">
        <nav aria-label={{i18n "discourse_user_cosmetics.admin.title"}}>
          <ul class="nav nav-pills duc-admin-kind-nav" role="tablist">
            {{#each this.tabs as |tab|}}
              <li>
                <button
                  type="button"
                  role="tab"
                  aria-selected={{if tab.active "true" "false"}}
                  class={{if tab.active "active"}}
                  {{on "click" (fn this.setKind tab.kind)}}
                >
                  <span class="duc-admin-kind-label">{{tab.label}}</span>
                  <span
                    class="duc-admin-kind-count"
                    aria-hidden="true"
                  >{{tab.count}}</span>
                </button>
              </li>
            {{/each}}
          </ul>
        </nav>
      </section>

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
        <div class="duc-admin-table-wrap">
          <table class="duc-admin-table">
            <thead>
              <tr>
                <th>{{i18n
                    "discourse_user_cosmetics.admin.table.preview"
                  }}</th>
                <th>{{i18n "discourse_user_cosmetics.admin.table.name"}}</th>
                <th>{{i18n "discourse_user_cosmetics.admin.table.group"}}</th>
                <th>{{i18n "discourse_user_cosmetics.admin.table.owners"}}</th>
                <th>{{i18n "discourse_user_cosmetics.admin.table.enabled"}}</th>
                <th>{{i18n "discourse_user_cosmetics.admin.table.actions"}}</th>
              </tr>
            </thead>
            <tbody>
              {{#each this.visibleItems as |item|}}
                <tr>
                  <td
                    data-label={{i18n
                      "discourse_user_cosmetics.admin.table.preview"
                    }}
                    class="duc-admin-preview-cell"
                  >
                    <div
                      class="duc-admin-preview-swatch"
                      style={{item.previewStyle}}
                    ></div>
                  </td>
                  <td
                    data-label={{i18n
                      "discourse_user_cosmetics.admin.table.name"
                    }}
                    class="duc-admin-name-cell"
                  >
                    <div class="duc-admin-name-copy">
                      <div class="duc-admin-name-line">
                        <span class="duc-admin-item-name">{{item.name}}</span>
                        {{#if item.is_default}}
                          <span class="duc-admin-default-badge">{{i18n
                              "discourse_user_cosmetics.admin.default_badge"
                            }}</span>
                        {{/if}}
                      </div>
                      {{#if item.description}}
                        <span
                          class="duc-admin-item-description"
                        >{{item.description}}</span>
                      {{/if}}
                    </div>
                  </td>
                  <td
                    data-label={{i18n
                      "discourse_user_cosmetics.admin.table.group"
                    }}
                  >
                    {{item.groupsLabel}}
                  </td>
                  <td
                    data-label={{i18n
                      "discourse_user_cosmetics.admin.table.owners"
                    }}
                  >
                    {{item.owner_count}}
                  </td>
                  <td
                    data-label={{i18n
                      "discourse_user_cosmetics.admin.table.enabled"
                    }}
                  >
                    <span
                      class={{if
                        item.enabled
                        "duc-admin-status-badge duc-admin-status-badge--enabled"
                        "duc-admin-status-badge duc-admin-status-badge--disabled"
                      }}
                    >
                      {{if
                        item.enabled
                        (i18n "discourse_user_cosmetics.admin.status.enabled")
                        (i18n "discourse_user_cosmetics.admin.status.disabled")
                      }}
                    </span>
                  </td>
                  <td
                    data-label={{i18n
                      "discourse_user_cosmetics.admin.table.actions"
                    }}
                    class="duc-admin-row-actions"
                  >
                    <div class="duc-admin-row-action-buttons">
                      <DButton
                        @icon="pencil"
                        @translatedLabel={{i18n
                          "discourse_user_cosmetics.admin.edit_item"
                        }}
                        @action={{fn this.startEdit item}}
                        class="btn-small duc-admin-edit-item"
                      />
                      <DButton
                        @icon="trash-can"
                        @translatedLabel={{i18n
                          "discourse_user_cosmetics.admin.delete"
                        }}
                        @action={{fn this.deleteItem item}}
                        class="btn-small btn-danger duc-admin-delete-item"
                      />
                    </div>
                  </td>
                </tr>
              {{/each}}
            </tbody>
          </table>
        </div>
      {{else}}
        <p class="duc-admin-empty">{{i18n
            "discourse_user_cosmetics.admin.no_items"
          }}</p>
      {{/if}}
    </div>
  </template>
}
