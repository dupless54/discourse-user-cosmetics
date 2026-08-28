# frozen_string_literal: true

module ::DiscourseUserCosmetics
  class AdminItemsController < ::Admin::AdminController
    requires_plugin DiscourseUserCosmetics::PLUGIN_NAME

    # Admin::AdminController already restricts this surface to staff. Cosmetic
    # catalog management is intentionally limited further to full admins.
    before_action :ensure_current_user_is_admin

    # GET /admin/plugins/user-cosmetics/items.json?kind=avatar_frame
    def index
      items = DiscourseUserCosmetics::Item.ordered.includes(:groups, :image_upload, effect_layers: :image_upload)
      items = items.for_kind(params[:kind]) if params[:kind].present?
      items = items.to_a
      owner_counts =
        DiscourseUserCosmetics::UserItem.where(item_id: items.map(&:id)).group(:item_id).count

      render json: {
               items: items.map { |item| admin_serialize(item, owner_count: owner_counts.fetch(item.id, 0)) },
               groups: ::Group.order(:name).pluck(:id, :name).map { |id, name| { id: id, name: name } },
             }
    end

    # POST /admin/plugins/user-cosmetics/items.json
    def create
      item = DiscourseUserCosmetics::Item.new(item_params)
      item.kind = params.dig(:item, :kind).to_s
      item.created_by_id = current_user.id
      save_item(item)
    end

    # PUT /admin/plugins/user-cosmetics/items/:id.json
    def update
      item = DiscourseUserCosmetics::Item.find(params[:id])
      item.assign_attributes(item_params)
      save_item(item)
    end

    # DELETE /admin/plugins/user-cosmetics/items/:id.json
    def destroy
      item = DiscourseUserCosmetics::Item.find(params[:id])
      item.destroy!
      render json: success_json
    end

    # POST /admin/plugins/user-cosmetics/items/:id/grant.json { username: }
    def grant
      item = DiscourseUserCosmetics::Item.find(params[:id])
      user = find_user!(params[:username])
      was_usable = item.usable_by?(user)

      user_item =
        DiscourseUserCosmetics::UserItem.find_or_create_by!(item_id: item.id, user_id: user.id) do |ui|
          ui.granted_by_id = current_user.id
        end

      if user_item.previously_new_record? && !was_usable
        # A new direct grant can reactivate a stale selected item. Only that
        # user's presentation state (and CSS when applicable) needs invalidation.
        DiscourseUserCosmetics::Presenter.invalidate_direct_entitlement_change!(
          user_id: user.id,
          item: item,
        )
      end

      render json: success_json.merge(owners: owner_usernames(item))
    end

    # DELETE /admin/plugins/user-cosmetics/items/:id/revoke.json { username: }
    def revoke
      item = DiscourseUserCosmetics::Item.find(params[:id])
      user = find_user!(params[:username])

      # UserItem#after_destroy clears the active slot only when this revoke
      # actually removes the user's final entitlement to the item.
      DiscourseUserCosmetics::UserItem.where(item_id: item.id, user_id: user.id).destroy_all

      render json: success_json.merge(owners: owner_usernames(item))
    end

    # GET /admin/plugins/user-cosmetics/items/:id/owners.json
    def owners
      item = DiscourseUserCosmetics::Item.find(params[:id])
      render json: { owners: owner_usernames(item) }
    end

    private

    def ensure_current_user_is_admin
      raise Discourse::InvalidAccess unless current_user&.admin?
    end

    def find_user!(username)
      user = ::User.find_by(username_lower: username.to_s.downcase)
      raise Discourse::NotFound unless user
      user
    end

    def owner_usernames(item)
      DiscourseUserCosmetics::UserItem
        .where(item_id: item.id)
        .joins(:user)
        .pluck("users.username")
        .sort
    end

    def save_item(item)
      serialized = nil
      creating = item.new_record?
      payload = params.require(:item)
      replace_groups = creating || payload.key?(:group_ids)
      replace_layers = creating || payload.key?(:layers)

      ActiveRecord::Base.transaction do
        item.save!
        replace_groups!(item) if replace_groups
        save_effect_layers(item) if item.kind == "profile_effect" && replace_layers
        DiscourseUserCosmetics::SelectionService.clear_invalid_for_item!(item, bump: false)
        serialized = admin_serialize(item.reload)
      end

      DiscourseUserCosmetics::Presenter.bump_version!
      render json: serialized
    rescue ActiveRecord::RecordInvalid => e
      render_json_error(e.record, status: 422)
    end

    def replace_groups!(item)
      group_ids = Array(params.dig(:item, :group_ids)).map(&:to_i).reject(&:zero?).uniq

      item.item_groups.destroy_all
      group_ids.each { |group_id| item.item_groups.create!(group_id: group_id) }
    end

    def save_effect_layers(item)
      item.effect_layers.destroy_all

      effect_layers_params.each do |layer_params|
        layer = layer_params.to_h.with_indifferent_access
        anchor = layer[:anchor].to_s.downcase
        stack_order = (layer[:stack_order] || layer[:stackOrder]).to_s.downcase
        image_upload_id = (layer[:image_upload_id] || layer[:imageUploadId]).presence
        image_url =
          (layer[:image_url] || layer[:imageUrl] || layer[:raw_image_url] || layer[:rawImageUrl]).presence

        item.effect_layers.create!(
          anchor: anchor,
          stack_order: stack_order,
          image_upload_id: image_upload_id,
          image_url: image_upload_id.present? ? nil : image_url,
        )
      end
    end

    def effect_layers_params
      permitted =
        params.require(:item).permit(
          layers: %i[
            anchor
            stack_order
            stackOrder
            image_upload_id
            imageUploadId
            image_url
            imageUrl
            raw_image_url
            rawImageUrl
          ],
        )

      layers = permitted[:layers]
      return [] if layers.blank?

      layers.is_a?(ActionController::Parameters) ? layers.values : Array(layers)
    end

    def admin_serialize(item, owner_count: nil)
      image_upload = item.image_upload
      raw_image_url = image_upload ? nil : safe_admin_asset_url(item.image_url)
      groups = item.groups.to_a

      {
        id: item.id,
        kind: item.kind,
        name: item.name,
        slug: item.slug,
        description: item.description,
        image_url: image_upload ? item.resolved_image_url : raw_image_url,
        image_upload_id: image_upload&.id,
        raw_image_url: raw_image_url,
        gradient_from: item.gradient_from,
        gradient_to: item.gradient_to,
        glow_color: item.glow_color,
        rarity_label: item.rarity_label,
        rarity_color: item.rarity_color,
        sort_order: item.sort_order,
        enabled: item.enabled,
        is_default: item.is_default,
        group_ids: groups.map(&:id),
        group_names: groups.map(&:name),
        owner_count: owner_count.nil? ? item.user_items.count : owner_count,
        created_at: item.created_at,
        effect_inner_width: item.resolved_effect_inner_width,
        effect_overflow_top: item.effect_overflow_top || 0,
        effect_overflow_bottom: item.effect_overflow_bottom || 0,
        effect_overflow_horizontal: item.effect_overflow_horizontal || 0,
        effect_side_offset_top: item.effect_side_offset_top || 0,
        effect_side_offset_bottom: item.effect_side_offset_bottom || 0,
        layers: item.effect_layers.filter_map { |layer| admin_serialize_layer(layer) },
      }
    end

    def admin_serialize_layer(layer)
      image_upload = layer.image_upload
      raw_image_url = image_upload ? nil : safe_admin_asset_url(layer.image_url)
      return if image_upload.blank? && raw_image_url.blank?

      {
        anchor: layer.anchor,
        stack_order: layer.stack_order,
        image_upload_id: image_upload&.id,
        raw_image_url: raw_image_url,
        image_url: image_upload ? layer.resolved_image_url : raw_image_url,
      }
    end

    def safe_admin_asset_url(url)
      return if url.blank?

      url if DiscourseUserCosmetics::AssetPolicy.valid_url?(url)
    end

    def item_params
      params.require(:item).permit(
        :name,
        :description,
        :image_url,
        :image_upload_id,
        :gradient_from,
        :gradient_to,
        :glow_color,
        :rarity_label,
        :rarity_color,
        :sort_order,
        :enabled,
        :is_default,
        :effect_inner_width,
        :effect_overflow_top,
        :effect_overflow_bottom,
        :effect_overflow_horizontal,
        :effect_side_offset_top,
        :effect_side_offset_bottom,
      )
    end
  end
end
