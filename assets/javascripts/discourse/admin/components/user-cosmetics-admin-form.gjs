import Component from "@glimmer/component";
import { cached, tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DButton from "discourse/ui-kit/d-button";
import { i18n as t } from "discourse-i18n";
import UserCosmeticsLayerUpload from "./user-cosmetics-layer-upload";

const LAYER_SLOTS = [
  { anchor: "full", stackOrder: "front", labelKey: "layer_full_front" },
  { anchor: "full", stackOrder: "back", labelKey: "layer_full_back" },
  { anchor: "top", stackOrder: "front", labelKey: "layer_top_front" },
  { anchor: "top", stackOrder: "back", labelKey: "layer_top_back" },
  { anchor: "bottom", stackOrder: "front", labelKey: "layer_bottom_front" },
  { anchor: "bottom", stackOrder: "back", labelKey: "layer_bottom_back" },
  { anchor: "left", stackOrder: "front", labelKey: "layer_left_front" },
  { anchor: "left", stackOrder: "back", labelKey: "layer_left_back" },
  { anchor: "right", stackOrder: "front", labelKey: "layer_right_front" },
  { anchor: "right", stackOrder: "back", labelKey: "layer_right_back" },
];

export default class UserCosmeticsAdminForm extends Component {
  @tracked imageUploadId = this.args.item.image_upload_id ?? null;
  @tracked rawImageUrl =
    this.args.item.raw_image_url || this.args.item.image_url || "";
  @tracked gradientFrom = this.args.item.gradient_from ?? "";
  @tracked gradientTo = this.args.item.gradient_to ?? "";
  @tracked glowColor = this.args.item.glow_color ?? "";
  @tracked rarityColor = this.args.item.rarity_color ?? "";
  @tracked groupIds = [...(this.args.item.group_ids ?? [])];

  @tracked effectOverflowTop = this.args.item.effect_overflow_top ?? 300;
  @tracked effectOverflowBottom = this.args.item.effect_overflow_bottom ?? 140;
  @tracked effectOverflowHorizontal =
    this.args.item.effect_overflow_horizontal ?? 60;
  @tracked effectSideOffsetTop = this.args.item.effect_side_offset_top ?? 0;
  @tracked effectSideOffsetBottom =
    this.args.item.effect_side_offset_bottom ?? 0;

  currentLayers = new Map(
    (this.args.item.layers ?? []).map((layer) => [
      `${layer.anchor}:${layer.stack_order}`,
      { ...layer },
    ])
  );

  @tracked uploading = false;
  @tracked errorMessage = null;
  @tracked owners = [];
  @tracked grantUsername = "";

  constructor() {
    super(...arguments);
    this.loadOwners();
  }

  @cached
  get formData() {
    return {
      name: this.args.item.name ?? "",
      description: this.args.item.description ?? "",
      rarityLabel: this.args.item.rarity_label ?? "",
      sortOrder: this.args.item.sort_order ?? 0,
      enabled: this.args.item.enabled ?? true,
      isDefault: this.args.item.is_default ?? false,
    };
  }

  async loadOwners() {
    if (this.args.isNew || !this.args.item.id) {
      return;
    }

    try {
      const response = await ajax(
        `/admin/plugins/user-cosmetics/items/${this.args.item.id}/owners.json`
      );
      this.owners = response.owners ?? [];
    } catch {
      // Owner loading is supplementary. The edit form remains usable if it fails.
    }
  }

  get previewStyle() {
    if (this.rawImageUrl) {
      return `background-image: url("${this.rawImageUrl}");`;
    }
    if (this.gradientFrom && this.gradientTo) {
      return `background-image: linear-gradient(135deg, ${this.gradientFrom}, ${this.gradientTo});`;
    }
    return "";
  }

  get groupChoices() {
    return (this.args.groups ?? []).map((group) => ({
      id: group.id,
      name: group.name,
      checked: this.groupIds.includes(group.id),
    }));
  }

  get isProfileEffect() {
    return this.args.item.kind === "profile_effect";
  }

  get layerSlots() {
    return LAYER_SLOTS.map((slot) => ({
      ...slot,
      label: t(`discourse_user_cosmetics.admin.fields.${slot.labelKey}`),
      initialLayer:
        this.currentLayers.get(`${slot.anchor}:${slot.stackOrder}`) ?? null,
    }));
  }

  @action
  onLayerChange(layerValue) {
    const key = `${layerValue.anchor}:${layerValue.stack_order}`;
    if (layerValue.image_upload_id || layerValue.image_url) {
      this.currentLayers.set(key, layerValue);
    } else {
      this.currentLayers.delete(key);
    }
  }

  @action
  updateEffectOverflowTop(event) {
    this.effectOverflowTop = Number(event.target.value) || 0;
  }

  @action
  updateEffectOverflowBottom(event) {
    this.effectOverflowBottom = Number(event.target.value) || 0;
  }

  @action
  updateEffectOverflowHorizontal(event) {
    this.effectOverflowHorizontal = Number(event.target.value) || 0;
  }

  @action
  updateEffectSideOffsetTop(event) {
    this.effectSideOffsetTop = Number(event.target.value) || 0;
  }

  @action
  updateEffectSideOffsetBottom(event) {
    this.effectSideOffsetBottom = Number(event.target.value) || 0;
  }

  @action
  updateRawImageUrl(event) {
    this.rawImageUrl = event.target.value;
    this.imageUploadId = null;
  }

  @action
  updateGradientFrom(event) {
    this.gradientFrom = event.target.value;
  }

  @action
  updateGradientTo(event) {
    this.gradientTo = event.target.value;
  }

  @action
  updateGlowColor(event) {
    this.glowColor = event.target.value;
  }

  @action
  updateRarityColor(event) {
    this.rarityColor = event.target.value;
  }

  @action
  toggleGroup(groupId) {
    if (this.groupIds.includes(groupId)) {
      this.groupIds = this.groupIds.filter((id) => id !== groupId);
    } else {
      this.groupIds = [...this.groupIds, groupId];
    }
  }

  @action
  async uploadImage(event) {
    const file = event.target.files?.[0];
    event.target.value = "";
    if (!file) {
      return;
    }

    this.uploading = true;
    this.errorMessage = null;

    try {
      const formData = new FormData();
      formData.append("file", file);
      formData.append("type", "composer");
      formData.append("synchronous", "true");

      const result = await ajax("/uploads.json", {
        type: "POST",
        data: formData,
        processData: false,
        contentType: false,
      });

      this.imageUploadId = result.id;
      this.rawImageUrl = result.url;
    } catch (error) {
      this.errorMessage = t("discourse_user_cosmetics.admin.upload_error");
      popupAjaxError(error);
    } finally {
      this.uploading = false;
    }
  }

  @action
  clearImage() {
    this.imageUploadId = null;
    this.rawImageUrl = "";
  }

  @action
  updateGrantUsername(event) {
    this.grantUsername = event.target.value;
  }

  @action
  async grantToUser() {
    const username = this.grantUsername.trim();
    if (!username || !this.args.item.id) {
      return;
    }

    try {
      const response = await ajax(
        `/admin/plugins/user-cosmetics/items/${this.args.item.id}/grant.json`,
        { type: "POST", data: { username } }
      );
      this.owners = response.owners ?? this.owners;
      this.grantUsername = "";
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async revokeFromUser(username) {
    if (!this.args.item.id) {
      return;
    }

    try {
      const response = await ajax(
        `/admin/plugins/user-cosmetics/items/${this.args.item.id}/revoke.json`,
        { type: "DELETE", data: { username } }
      );
      this.owners =
        response.owners ?? this.owners.filter((user) => user !== username);
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async save({
    name,
    description,
    rarityLabel,
    sortOrder,
    enabled,
    isDefault,
  }) {
    this.errorMessage = null;

    try {
      const payload = {
        item: {
          kind: this.args.item.kind,
          name,
          description,
          image_upload_id: this.imageUploadId,
          image_url: this.imageUploadId ? null : this.rawImageUrl || null,
          gradient_from: this.gradientFrom || null,
          gradient_to: this.gradientTo || null,
          glow_color: this.glowColor || null,
          rarity_label: rarityLabel || null,
          rarity_color: this.rarityColor || null,
          sort_order: Number(sortOrder) || 0,
          enabled,
          is_default: isDefault,
          group_ids: this.groupIds,
        },
      };

      if (this.isProfileEffect) {
        payload.item.effect_inner_width = 1200;
        payload.item.effect_overflow_top = this.effectOverflowTop;
        payload.item.effect_overflow_bottom = this.effectOverflowBottom;
        payload.item.effect_overflow_horizontal = this.effectOverflowHorizontal;
        payload.item.effect_side_offset_top = this.effectSideOffsetTop;
        payload.item.effect_side_offset_bottom = this.effectSideOffsetBottom;
        payload.item.layers = Array.from(this.currentLayers.values());
      }

      let response;
      if (this.args.isNew) {
        response = await ajax("/admin/plugins/user-cosmetics/items.json", {
          type: "POST",
          data: payload,
        });
      } else {
        response = await ajax(
          `/admin/plugins/user-cosmetics/items/${this.args.item.id}.json`,
          { type: "PUT", data: payload }
        );
      }

      this.args.onSaved?.(response);
    } catch (error) {
      this.errorMessage = t("discourse_user_cosmetics.admin.save_error");
      popupAjaxError(error);
    }
  }

  @action
  cancel() {
    this.args.onCancel?.();
  }

  <template>
    <Form
      @data={{this.formData}}
      @onSubmit={{this.save}}
      class="duc-admin-form"
      as |form|
    >
      <div class="duc-admin-form-preview" style={{this.previewStyle}}></div>

      <form.Field
        @name="name"
        @title={{t "discourse_user_cosmetics.admin.fields.name"}}
        @format="large"
        @type="input"
        as |field|
      >
        <field.Control
          placeholder={{t
            "discourse_user_cosmetics.admin.fields.name_placeholder"
          }}
          data-duc-admin-field="name"
        />
      </form.Field>

      <form.Field
        @name="description"
        @title={{t "discourse_user_cosmetics.admin.fields.description"}}
        @format="large"
        @type="input"
        as |field|
      >
        <field.Control
          placeholder={{t
            "discourse_user_cosmetics.admin.fields.description_placeholder"
          }}
          data-duc-admin-field="description"
        />
      </form.Field>

      {{#unless this.isProfileEffect}}
        <div class="duc-admin-field">
          <span>{{t "discourse_user_cosmetics.admin.fields.image"}}</span>
          <div class="duc-admin-image-controls">
            <label class="btn duc-upload-btn">
              {{#if this.uploading}}
                {{t "discourse_user_cosmetics.admin.fields.uploading"}}
              {{else}}
                {{t "discourse_user_cosmetics.admin.fields.upload"}}
              {{/if}}
              <input
                type="file"
                accept="image/png,image/jpeg,image/gif,image/webp"
                disabled={{this.uploading}}
                {{on "change" this.uploadImage}}
                class="duc-hidden-file-input"
              />
            </label>
            {{#if this.rawImageUrl}}
              <DButton
                @icon="xmark"
                @translatedLabel={{t
                  "discourse_user_cosmetics.admin.fields.remove_image"
                }}
                @action={{this.clearImage}}
                class="btn-small"
              />
            {{/if}}
          </div>
          <input
            type="text"
            value={{this.rawImageUrl}}
            {{on "input" this.updateRawImageUrl}}
            placeholder={{t
              "discourse_user_cosmetics.admin.fields.or_paste_url"
            }}
            class="duc-admin-url-input"
          />
        </div>

        <div class="duc-admin-field duc-admin-field-row">
          <label>
            <span>{{t
                "discourse_user_cosmetics.admin.fields.gradient_from"
              }}</span>
            <input
              type="color"
              value={{this.gradientFrom}}
              {{on "input" this.updateGradientFrom}}
            />
          </label>
          <label>
            <span>{{t
                "discourse_user_cosmetics.admin.fields.gradient_to"
              }}</span>
            <input
              type="color"
              value={{this.gradientTo}}
              {{on "input" this.updateGradientTo}}
            />
          </label>
          <label>
            <span>{{t
                "discourse_user_cosmetics.admin.fields.glow_color"
              }}</span>
            <input
              type="color"
              value={{this.glowColor}}
              {{on "input" this.updateGlowColor}}
            />
          </label>
        </div>
      {{/unless}}

      {{#if this.isProfileEffect}}
        <div class="duc-admin-field duc-effect-layers">
          <span>{{t "discourse_user_cosmetics.admin.fields.layers"}}</span>
          <p class="duc-admin-help">{{t
              "discourse_user_cosmetics.admin.fields.layers_help"
            }}</p>
          <div class="duc-layer-grid">
            {{#each this.layerSlots as |slot|}}
              <UserCosmeticsLayerUpload
                @anchor={{slot.anchor}}
                @stackOrder={{slot.stackOrder}}
                @label={{slot.label}}
                @layer={{slot.initialLayer}}
                @onChange={{this.onLayerChange}}
              />
            {{/each}}
          </div>
        </div>

        <div class="duc-admin-field duc-admin-field-row">
          <label>
            <span>{{t
                "discourse_user_cosmetics.admin.fields.overflow_top"
              }}</span>
            <input
              type="number"
              min="0"
              value={{this.effectOverflowTop}}
              {{on "input" this.updateEffectOverflowTop}}
            />
          </label>
          <label>
            <span>{{t
                "discourse_user_cosmetics.admin.fields.overflow_bottom"
              }}</span>
            <input
              type="number"
              min="0"
              value={{this.effectOverflowBottom}}
              {{on "input" this.updateEffectOverflowBottom}}
            />
          </label>
          <label>
            <span>{{t
                "discourse_user_cosmetics.admin.fields.overflow_horizontal"
              }}</span>
            <input
              type="number"
              min="0"
              value={{this.effectOverflowHorizontal}}
              {{on "input" this.updateEffectOverflowHorizontal}}
            />
          </label>
        </div>
        <p class="duc-admin-help">{{t
            "discourse_user_cosmetics.admin.fields.overflow_help"
          }}</p>

        <div class="duc-admin-field duc-admin-field-row">
          <label>
            <span>{{t
                "discourse_user_cosmetics.admin.fields.side_offset_top"
              }}</span>
            <input
              type="number"
              min="0"
              value={{this.effectSideOffsetTop}}
              {{on "input" this.updateEffectSideOffsetTop}}
            />
          </label>
          <label>
            <span>{{t
                "discourse_user_cosmetics.admin.fields.side_offset_bottom"
              }}</span>
            <input
              type="number"
              min="0"
              value={{this.effectSideOffsetBottom}}
              {{on "input" this.updateEffectSideOffsetBottom}}
            />
          </label>
        </div>
        <p class="duc-admin-help">{{t
            "discourse_user_cosmetics.admin.fields.side_offset_help"
          }}</p>
      {{/if}}

      <div class="duc-admin-field-row duc-admin-formkit-row">
        <form.Field
          @name="rarityLabel"
          @title={{t "discourse_user_cosmetics.admin.fields.rarity_label"}}
          @format="full"
          @type="input"
          class="duc-admin-formkit-field"
          as |field|
        >
          <field.Control
            placeholder={{t
              "discourse_user_cosmetics.admin.fields.rarity_label_placeholder"
            }}
            data-duc-admin-field="rarity-label"
          />
        </form.Field>

        <label>
          <span>{{t
              "discourse_user_cosmetics.admin.fields.rarity_color"
            }}</span>
          <input
            type="color"
            value={{this.rarityColor}}
            {{on "input" this.updateRarityColor}}
          />
        </label>

        <form.Field
          @name="sortOrder"
          @title={{t "discourse_user_cosmetics.admin.fields.sort_order"}}
          @format="full"
          @type="input-number"
          class="duc-admin-formkit-field"
          as |field|
        >
          <field.Control data-duc-admin-field="sort-order" />
        </form.Field>
      </div>

      <div class="duc-admin-form-options">
        <form.CheckboxGroup as |checkboxGroup|>
          <checkboxGroup.Field
            @name="enabled"
            @title={{t "discourse_user_cosmetics.admin.fields.enabled"}}
            @format="full"
            @type="checkbox"
            class="duc-admin-checkbox"
            as |field|
          >
            <field.Control data-duc-admin-field="enabled" />
          </checkboxGroup.Field>

          <checkboxGroup.Field
            @name="isDefault"
            @title={{t "discourse_user_cosmetics.admin.fields.is_default"}}
            @format="full"
            @type="checkbox"
            class="duc-admin-checkbox"
            as |field|
          >
            <field.Control data-duc-admin-field="is-default" />
          </checkboxGroup.Field>
        </form.CheckboxGroup>
      </div>

      <div class="duc-admin-field">
        <span>{{t "discourse_user_cosmetics.admin.fields.groups"}}</span>
        <p class="duc-admin-help">{{t
            "discourse_user_cosmetics.admin.fields.groups_help"
          }}</p>
        <div class="duc-admin-group-list">
          {{#each this.groupChoices as |group|}}
            <label class="duc-admin-checkbox">
              <input
                type="checkbox"
                checked={{group.checked}}
                {{on "change" (fn this.toggleGroup group.id)}}
              />
              <span>{{group.name}}</span>
            </label>
          {{/each}}
        </div>
      </div>

      {{#unless @isNew}}
        <div class="duc-admin-field duc-admin-owners">
          <span>{{t "discourse_user_cosmetics.admin.owners.title"}}</span>
          <div class="duc-admin-owners-list">
            {{#each this.owners as |username|}}
              <span class="duc-admin-owner-chip">
                {{username}}
                <button
                  type="button"
                  title={{t "discourse_user_cosmetics.admin.owners.remove"}}
                  {{on "click" (fn this.revokeFromUser username)}}
                >×</button>
              </span>
            {{else}}
              <span class="duc-admin-owners-none">{{t
                  "discourse_user_cosmetics.admin.owners.none"
                }}</span>
            {{/each}}
          </div>
          <div class="duc-admin-owners-add">
            <input
              type="text"
              value={{this.grantUsername}}
              {{on "input" this.updateGrantUsername}}
              placeholder={{t
                "discourse_user_cosmetics.admin.owners.add_placeholder"
              }}
            />
            <DButton
              @translatedLabel={{t
                "discourse_user_cosmetics.admin.owners.add"
              }}
              @action={{this.grantToUser}}
              class="btn-small"
            />
          </div>
        </div>
      {{/unless}}

      {{#if this.errorMessage}}
        <p class="duc-admin-form-error">{{this.errorMessage}}</p>
      {{/if}}

      <form.Actions class="duc-admin-form-actions">
        <form.Submit @label="discourse_user_cosmetics.admin.save" />
        <DButton
          @translatedLabel={{t "discourse_user_cosmetics.admin.cancel"}}
          @action={{this.cancel}}
          class="btn-default"
        />
      </form.Actions>
    </Form>
  </template>
}
