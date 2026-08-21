# frozen_string_literal: true

module ::DiscourseUserCosmetics
  class ItemsController < ::ApplicationController
    requires_plugin DiscourseUserCosmetics::PLUGIN_NAME
    requires_login

    # GET /user-cosmetics/mine.json
    # Returns every enabled item grouped by kind, flagged with whether the
    # current user owns/can-use it, plus the user's currently active picks.
    def mine
      items = DiscourseUserCosmetics::Item.enabled.ordered.includes(:groups)

      grouped =
        DiscourseUserCosmetics::Item::KINDS.each_with_object({}) do |kind, memo|
          memo[kind] = items.select { |i| i.kind == kind }.map { |item| serialize_for_user(item) }
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
      kind = params[:kind].to_s
      raise Discourse::InvalidParameters.new(:kind) unless DiscourseUserCosmetics::Item::KINDS.include?(kind)

      item_id = params[:item_id].presence

      if item_id
        item = DiscourseUserCosmetics::Item.find_by(id: item_id, kind: kind, enabled: true)
        raise Discourse::NotFound unless item
        raise Discourse::InvalidAccess unless item.usable_by?(current_user)
      end

      selection = DiscourseUserCosmetics::UserSelection.find_or_initialize_by(user_id: current_user.id)
      selection.public_send("#{DiscourseUserCosmetics::UserSelection.field_for(kind)}=", item_id)
      selection.save!

      DiscourseUserCosmetics::Presenter.bump_version!

      render json: success_json
    end

    private

    def serialize_for_user(item)
      {
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
    end
  end
end
