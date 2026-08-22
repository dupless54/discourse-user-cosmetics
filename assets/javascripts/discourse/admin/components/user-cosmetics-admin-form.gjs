import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { fn } from "@ember/helper";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DButton from "discourse/components/d-button";
import { t } from "../../lib/duc-i18n";
import UserCosmeticsLayerUpload from "./user-cosmetics-layer-upload";

// Yeni "Sol" ve "Sağ" (left/right) katmanlarımızı sisteme dahil ettik.
// Sistem bu listeyi okuyup otomatik olarak 8 kutu çizecek.
// ... (import kısımları) ...

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

// ... (dosyanın geri kalanı aynı) ...

export default class UserCosmeticsAdminForm extends Component {
  @tracked name = this.args.item.name ?? "";
  @tracked description = this.args.item.description ?? "";
  @tracked imageUploadId = this.args.item.image_upload_id ?? null;
  @tracked rawImageUrl = this.args.item.raw_image_url || this.args.item.image_url || "";
  @tracked gradientFrom = this.args.item.gradient_from ?? "";
  @tracked gradientTo = this.args.item.gradient_to ?? "";
  @tracked glowColor = this.args.item.glow_color ?? "";
  @tracked rarityLabel = this.args.item.rarity_label ?? "";
  @tracked rarityColor = this.args.item.rarity_color ?? "";
  @tracked sortOrder = this.args.item.sort_order ?? 0;
  @tracked enabled = this.args.item.enabled ?? true;
  @tracked isDefault = this.args.item.is_default ?? false;
  @tracked groupIds = [...(this.args.item.group_ids ?? [])];

  @tracked effectOverflowTop = this.args.item.effect_overflow_top ?? 300;
  @tracked effectOverflowBottom = this.args.item.effect_overflow_bottom ?? 140;
  @tracked effectOverflowHorizontal = this.args.item.effect_overflow_horizontal ?? 60;

  currentLayers = new Map(
    (this.args.item.layers ?? []).map((l) => [`${l.anchor}:${l.stack_order}`, { ...l }])
  );

  @tracked uploading = false;
  @tracked saving = false;
  @tracked errorMessage = null;

  @tracked owners = [];
  @tracked grantUsername = "";

  constructor() {
    super(...arguments);
    this.loadOwners();
  }

  async loadOwners() {
    if (this.args.isNew || !this.args.item.id) {
      return;
    }
    try {
      const res = await ajax(
        `/admin/plugins/user-cosmetics/items/${this.args.item.id}/owners.json`
      );
      this.owners = res.owners ?? [];
    } catch (e) {
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
    return (this.args.groups ?? []).map((g) => ({
      id: g.id,
      name: g.name,
      checked: this.groupIds.includes(g.id),
    }));
  }

  get isProfileEffect() {
    return this.args.item.kind === "profile_effect";
  }

  get layerSlots() {
    return LAYER_SLOTS.map((slot) => ({
      ...slot,
      label: t(`discourse_user_cosmetics.admin.fields.${slot.labelKey}`),
      initialLayer: this.currentLayers.get(`${slot.anchor}:${slot.stackOrder}`) ?? null,
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
  updateEffectOverflowTop(e) {
    this.effectOverflowTop = Number(e.target.value) || 0;
  }

  @action
  updateEffectOverflowBottom(e) {
    this.effectOverflowBottom = Number(e.target.value) || 0;
  }

  @action
  updateEffectOverflowHorizontal(e) {
    this.effectOverflowHorizontal = Number(e.target.value) || 0;
  }

  @action
  updateName(e) {
    this.name = e.target.value;
  }

  @action
  updateDescription(e) {
    this.description = e.target.value;
  }

  @action
  updateRawImageUrl(e) {
    this.rawImageUrl = e.target.value;
    this.imageUploadId = null;
  }

  @action
  updateGradientFrom(e) {
    this.gradientFrom = e.target.value;
  }

  @action
  updateGradientTo(e) {
    this.gradientTo = e.target.value;
  }

  @action
  updateGlowColor(e) {
    this.glowColor = e.target.value;
  }

  @action
  updateRarityLabel(e) {
    this.rarityLabel = e.target.value;
  }

  @action
  updateRarityColor(e) {
    this.rarityColor = e.target.value;
  }

  @action
  updateSortOrder(e) {
    this.sortOrder = Number(e.target.value) || 0;
  }

  @action
  toggleEnabled() {
    this.enabled = !this.enabled;
  }

  @action
  toggleIsDefault() {
    this.isDefault = !this.isDefault;
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
    } catch (e) {
      this.errorMessage = t("discourse_user_cosmetics.admin.upload_error");
      popupAjaxError(e);
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
  updateGrantUsername(e) {
    this.grantUsername = e.target.value;
  }

  @action
  async grantToUser() {
    const username = this.grantUsername.trim();
    if (!username || !this.args.item.id) {
      return;
    }
    try {
      const res = await ajax(
        `/admin/plugins/user-cosmetics/items/${this.args.item.id}/grant.json`,
        { type: "POST", data: { username } }
      );
      this.owners = res.owners ?? this.owners;
      this.grantUsername = "";
    } catch (e) {
      popupAjaxError(e);
    }
  }

  @action
  async revokeFromUser(username) {
    if (!this.args.item.id) {
      return;
    }
    try {
      const res = await ajax(
        `/admin/plugins/user-cosmetics/items/${this.args.item.id}/revoke.json`,
        { type: "DELETE", data: { username } }
      );
      this.owners = res.owners ?? this.owners.filter((u) => u !== username);
    } catch (e) {
      popupAjaxError(e);
    }
  }

  @action
  async save() {
    this.saving = true;
    this.errorMessage = null;
    try {
      const payload = {
        item: {
          kind: this.args.item.kind,
          name: this.name,
          description: this.description,
          image_upload_id: this.imageUploadId,
          image_url: this.imageUploadId ? null : this.rawImageUrl || null,
          gradient_from: this.gradientFrom || null,
          gradient_to: this.gradientTo || null,
          glow_color: this.glowColor || null,
          rarity_label: this.rarityLabel || null,
          rarity_color: this.rarityColor || null,
          sort_order: this.sortOrder,
          enabled: this.enabled,
          is_default: this.isDefault,
          group_ids: this.groupIds,
        },
      };

      if (this.isProfileEffect) {
        payload.item.effect_inner_width = 1200;
        payload.item.effect_overflow_top = this.effectOverflowTop;
        payload.item.effect_overflow_bottom = this.effectOverflowBottom;
        payload.item.effect_overflow_horizontal = this.effectOverflowHorizontal;
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
    } catch (e) {
      this.errorMessage = t("discourse_user_cosmetics.admin.save_error");
      popupAjaxError(e);
    } finally {
      this.saving = false;
    }
  }

  @action
  cancel() {
    this.args.onCancel?.();
  }

  <template>
    <div class="duc-admin-form">
      <div class="duc-admin-form-preview" style={{this.previewStyle}}></div>

      <label class="duc-admin-field">
        <span>{{t "discourse_user_cosmetics.admin.fields.name"}}</span>
        <input
          type="text"
          value={{this.name}}
          {{on "input" this.updateName}}
          placeholder={{t "discourse_user_cosmetics.admin.fields.name_placeholder"}}
        />
      </label>

      <label class="duc-admin-field">
        <span>{{t "discourse_user_cosmetics.admin.fields.description"}}</span>
        <input
          type="text"
          value={{this.description}}
          {{on "input" this.updateDescription}}
          placeholder={{t "discourse_user_cosmetics.admin.fields.description_placeholder"}}
        />
      </label>

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
                @translatedLabel={{t "discourse_user_cosmetics.admin.fields.remove_image"}}
                @action={{this.clearImage}}
                class="btn-small"
              />
            {{/if}}
          </div>
          <input
            type="text"
            value={{this.rawImageUrl}}
            {{on "input" this.updateRawImageUrl}}
            placeholder={{t "discourse_user_cosmetics.admin.fields.or_paste_url"}}
            class="duc-admin-url-input"
          />
        </div>

        <div class="duc-admin-field duc-admin-field-row">
          <label>
            <span>{{t "discourse_user_cosmetics.admin.fields.gradient_from"}}</span>
            <input type="color" value={{this.gradientFrom}} {{on "input" this.updateGradientFrom}} />
          </label>
          <label>
            <span>{{t "discourse_user_cosmetics.admin.fields.gradient_to"}}</span>
            <input type="color" value={{this.gradientTo}} {{on "input" this.updateGradientTo}} />
          </label>
          <label>
            <span>{{t "discourse_user_cosmetics.admin.fields.glow_color"}}</span>
            <input type="color" value={{this.glowColor}} {{on "input" this.updateGlowColor}} />
          </label>
        </div>
      {{/unless}}

      {{#if this.isProfileEffect}}
        <div class="duc-admin-field duc-effect-layers">
          <span>{{t "discourse_user_cosmetics.admin.fields.layers"}}</span>
          <p class="duc-admin-help">{{t "discourse_user_cosmetics.admin.fields.layers_help"}}</p>
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
            <span>{{t "discourse_user_cosmetics.admin.fields.overflow_top"}}</span>
            <input
              type="number"
              min="0"
              value={{this.effectOverflowTop}}
              {{on "input" this.updateEffectOverflowTop}}
            />
          </label>
          <label>
            <span>{{t "discourse_user_cosmetics.admin.fields.overflow_bottom"}}</span>
            <input
              type="number"
              min="0"
              value={{this.effectOverflowBottom}}
              {{on "input" this.updateEffectOverflowBottom}}
            />
          </label>
          <label>
            <span>{{t "discourse_user_cosmetics.admin.fields.overflow_horizontal"}}</span>
            <input
              type="number"
              min="0"
              value={{this.effectOverflowHorizontal}}
              {{on "input" this.updateEffectOverflowHorizontal}}
            />
          </label>
        </div>
        <p class="duc-admin-help">{{t "discourse_user_cosmetics.admin.fields.overflow_help"}}</p>
      {{/if}}

      <div class="duc-admin-field duc-admin-field-row">
        <label>
          <span>{{t "discourse_user_cosmetics.admin.fields.rarity_label"}}</span>
          <input
            type="text"
            value={{this.rarityLabel}}
            {{on "input" this.updateRarityLabel}}
            placeholder={{t "discourse_user_cosmetics.admin.fields.rarity_label_placeholder"}}
          />
        </label>
        <label>
          <span>{{t "discourse_user_cosmetics.admin.fields.rarity_color"}}</span>
          <input type="color" value={{this.rarityColor}} {{on "input" this.updateRarityColor}} />
        </label>
        <label>
          <span>{{t "discourse_user_cosmetics.admin.fields.sort_order"}}</span>
          <input type="number" value={{this.sortOrder}} {{on "input" this.updateSortOrder}} />
        </label>
      </div>

      <label class="duc-admin-field duc-admin-checkbox">
        <input type="checkbox" checked={{this.enabled}} {{on "change" this.toggleEnabled}} />
        <span>{{t "discourse_user_cosmetics.admin.fields.enabled"}}</span>
      </label>

      <label class="duc-admin-field duc-admin-checkbox">
        <input type="checkbox" checked={{this.isDefault}} {{on "change" this.toggleIsDefault}} />
        <span>{{t "discourse_user_cosmetics.admin.fields.is_default"}}</span>
      </label>

      <div class="duc-admin-field">
        <span>{{t "discourse_user_cosmetics.admin.fields.groups"}}</span>
        <p class="duc-admin-help">{{t "discourse_user_cosmetics.admin.fields.groups_help"}}</p>
        <div class="duc-admin-group-list">
          {{#each this.groupChoices as |g|}}
            <label class="duc-admin-checkbox">
              <input type="checkbox" checked={{g.checked}} {{on "change" (fn this.toggleGroup g.id)}} />
              <span>{{g.name}}</span>
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
              <span class="duc-admin-owners-none">{{t "discourse_user_cosmetics.admin.owners.none"}}</span>
            {{/each}}
          </div>
          <div class="duc-admin-owners-add">
            <input
              type="text"
              value={{this.grantUsername}}
              {{on "input" this.updateGrantUsername}}
              placeholder={{t "discourse_user_cosmetics.admin.owners.add_placeholder"}}
            />
            <DButton
              @translatedLabel={{t "discourse_user_cosmetics.admin.owners.add"}}
              @action={{this.grantToUser}}
              class="btn-small"
            />
          </div>
        </div>
      {{/unless}}

      {{#if this.errorMessage}}
        <p class="duc-admin-form-error">{{this.errorMessage}}</p>
      {{/if}}

      <div class="duc-admin-form-actions">
        <DButton
          @translatedLabel={{t "discourse_user_cosmetics.admin.save"}}
          @action={{this.save}}
          @isLoading={{this.saving}}
          class="btn-primary"
        />
        <DButton
          @translatedLabel={{t "discourse_user_cosmetics.admin.cancel"}}
          @action={{this.cancel}}
          class="btn-default"
        />
      </div>
    </div>
  </template>
}