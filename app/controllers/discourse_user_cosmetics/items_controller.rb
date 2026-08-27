# frozen_string_literal: true

module ::DiscourseUserCosmetics
  class ItemsController < ::ApplicationController
    requires_plugin DiscourseUserCosmetics::PLUGIN_NAME
    requires_login

    # GET /user-cosmetics/mine.json
    # Returns every enabled item grouped by kind, flagged with whether the
    # current user owns/can-use it, plus the user's currently active picks.
    def mine
      items = DiscourseUserCosmetics::Item.enabled.ordered.includes(:groups, effect_layers: :image_upload)

      grouped =
        DiscourseUserCosmetics::Item::KINDS.each_with_object({}) do |kind, memo|
          memo[kind] = items.select { |item| item.kind == kind }.map { |item| serialize_for_user(item) }
        end

      selection = DiscourseUserCosmetics::UserSelection.find_by(user_id: current_user.id)
      active =
        DiscourseUserCosmetics::Item::KINDS.each_with_object({}) do |kind, memo|
          memo[kind] = selection&.public_send(DiscourseUserCosmetics::UserSelection.field_for(kind))
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

      render json: success_json
    end

    private

    def serialize_for_user(item)
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
        owned: item.usable_by?(current_user),
        group_names: item.groups.map(&:name),
      }

      # Profile effects use positioned layers rather than one canonical image;
      # expose a representative image for the picker preview.
      base[:image_url] = DiscourseUserCosmetics::Presenter.effect_fields(item)[:image_url] if item.kind == "profile_effect"

      base
    end
  end
end
