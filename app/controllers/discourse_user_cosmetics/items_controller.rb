# frozen_string_literal: true

module ::DiscourseUserCosmetics
  class ItemsController < ::ApplicationController
    requires_plugin DiscourseUserCosmetics::PLUGIN_NAME
    requires_login

    # GET /user-cosmetics/mine.json
    # Returns enabled catalog items for currently enabled cosmetic kinds,
    # flagged with whether the current user can use each item.
    def mine
      enabled_kinds = DiscourseUserCosmetics::Item::KINDS.select { |kind| DiscourseUserCosmetics::Item.kind_enabled?(kind) }
      items =
        DiscourseUserCosmetics::Item.enabled
          .where(kind: enabled_kinds)
          .ordered
          .includes(:image_upload, effect_layers: :image_upload)
          .to_a

      usable_item_ids =
        DiscourseUserCosmetics::EntitlementResolver.usable_item_ids(
          user: current_user,
          items: items,
        )
      items_by_kind = items.group_by(&:kind)
      items_by_id = items.index_by(&:id)

      grouped =
        DiscourseUserCosmetics::Item::KINDS.each_with_object({}) do |kind, memo|
          memo[kind] =
            if enabled_kinds.include?(kind)
              Array(items_by_kind[kind]).map do |item|
                serialize_for_user(item, owned: usable_item_ids.key?(item.id))
              end
            else
              []
            end
        end

      selection = DiscourseUserCosmetics::UserSelection.find_by(user_id: current_user.id)
      active =
        DiscourseUserCosmetics::Item::KINDS.each_with_object({}) do |kind, memo|
          memo[kind] =
            visible_active_item_id(kind, selection, items_by_id, enabled_kinds, usable_item_ids)
        end

      render json: { items: grouped, active: active }
    end

    # PUT /user-cosmetics/select.json { kind:, item_id: }
    # item_id may be blank/nil to unequip that slot.
    def select
      DiscourseUserCosmetics::SelectionService.select!(
        user: current_user,
        kind: params[:kind],
        item_id: params[:item_id].presence,
      )

      render json: success_json.merge(cosmetics: DiscourseUserCosmetics::Presenter.summary_for(current_user))
    end

    private

    def visible_active_item_id(kind, selection, items_by_id, enabled_kinds, usable_item_ids)
      return nil unless selection && enabled_kinds.include?(kind)

      item_id = selection.public_send(DiscourseUserCosmetics::UserSelection.field_for(kind))
      return nil if item_id.blank?

      item = items_by_id[item_id]
      return nil unless item&.kind == kind && usable_item_ids.key?(item.id)

      item.id
    end

    def serialize_for_user(item, owned:)
      base = {
        id: item.id,
        kind: item.kind,
        name: item.name,
        description: item.description,
        image_url: item.resolved_image_url,
        gradient_from: item.gradient_from,
        gradient_to: item.gradient_to,
        glow_color: item.glow_color,
        rarity_label: item.rarity_label,
        rarity_color: item.rarity_color,
        owned: owned,
      }

      # Profile effects use positioned layers rather than one canonical image;
      # expose a representative image for the picker preview.
      base[:image_url] = DiscourseUserCosmetics::Presenter.effect_fields(item)[:image_url] if item.kind == "profile_effect"

      base
    end
  end
end
