import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DButton from "discourse/components/d-button";
import { t } from "../../lib/duc-i18n";

// One of the (at most) 4 slots a "profile_effect" item can have, matching
// Discord's layer schema: { anchor: "top"|"bottom", order: "front"|"back" }.
// Kept as its own small component so each slot manages its own upload state
// independently, and reports changes up via @onChange.
export default class UserCosmeticsLayerUpload extends Component {
  @tracked imageUploadId = this.args.layer?.image_upload_id ?? null;
  @tracked imageUrl = this.args.layer?.raw_image_url || this.args.layer?.image_url || "";
  @tracked uploading = false;

  get previewStyle() {
    if (!this.imageUrl) {
      return "";
    }
    return `background-image: url("${this.imageUrl}");`;
  }

  notify() {
    this.args.onChange?.({
      anchor: this.args.anchor,
      stack_order: this.args.stackOrder,
      image_upload_id: this.imageUploadId,
      image_url: this.imageUploadId ? null : this.imageUrl || null,
    });
  }

  @action
  async uploadFile(event) {
    const file = event.target.files?.[0];
    event.target.value = "";
    if (!file) {
      return;
    }

    this.uploading = true;
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
      this.imageUrl = result.url;
      this.notify();
    } catch (e) {
      popupAjaxError(e);
    } finally {
      this.uploading = false;
    }
  }

  @action
  updateUrl(event) {
    this.imageUrl = event.target.value;
    this.imageUploadId = null;
    this.notify();
  }

  @action
  clear() {
    this.imageUploadId = null;
    this.imageUrl = "";
    this.notify();
  }

  <template>
    <div class="duc-layer-slot">
      <div class="duc-layer-slot-label">{{@label}}</div>
      <div class="duc-layer-slot-preview" style={{this.previewStyle}}></div>
      <div class="duc-admin-image-controls">
        <label class="btn duc-upload-btn">
          {{#if this.uploading}}
            {{t "discourse_user_cosmetics.admin.fields.uploading"}}
          {{else}}
            {{t "discourse_user_cosmetics.admin.fields.upload"}}
          {{/if}}
          <input
            type="file"
            accept="image/png,image/gif,image/webp"
            disabled={{this.uploading}}
            {{on "change" this.uploadFile}}
            class="duc-hidden-file-input"
          />
        </label>
        {{#if this.imageUrl}}
          <DButton @icon="xmark" @action={{this.clear}} class="btn-small" />
        {{/if}}
      </div>
      <input
        type="text"
        value={{this.imageUrl}}
        {{on "input" this.updateUrl}}
        placeholder={{t "discourse_user_cosmetics.admin.fields.or_paste_url"}}
        class="duc-admin-url-input"
      />
    </div>
  </template>
}
