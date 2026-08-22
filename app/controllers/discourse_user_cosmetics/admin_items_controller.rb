# frozen_string_literal: true

module ::DiscourseUserCosmetics
  class AdminItemsController < ::Admin::AdminController
    requires_plugin DiscourseUserCosmetics::PLUGIN_NAME

    # Belt-and-suspenders: Admin::AdminController already restricts to staff,
    # but management of cosmetics (including image uploads) is intentionally
    # limited to full admins only. Written against only `current_user` and
    # `Discourse::InvalidAccess` (both rock solid) rather than a helper
    # method name that could vary between Discourse versions.
    before_action :ensure_current_user_is_admin

    # GET /admin/plugins/user-cosmetics/items.json?kind=avatar_frame
    def index
      items = DiscourseUserCosmetics::Item.ordered.includes(:groups, :image_upload, effect_layers: :image_upload)
      items = items.for_kind(params[:kind]) if params[:kind].present?

      render json: {
               items: items.map { |item| admin_serialize(item) },
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
      DiscourseUserCosmetics::Presenter.bump_version!
      render json: success_json
    end

    # POST /admin/plugins/user-cosmetics/items/:id/grant.json { username: }
    def grant
      item = DiscourseUserCosmetics::Item.find(params[:id])
      user = find_user!(params[:username])

      DiscourseUserCosmetics::UserItem.find_or_create_by!(item_id: item.id, user_id: user.id) do |ui|
        ui.granted_by_id = current_user.id
      end

      DiscourseUserCosmetics::Presenter.bump_version!
      render json: success_json.merge(owners: owner_usernames(item))
    end

    # DELETE /admin/plugins/user-cosmetics/items/:id/revoke.json { username: }
    def revoke
      item = DiscourseUserCosmetics::Item.find(params[:id])
      user = find_user!(params[:username])

      DiscourseUserCosmetics::UserItem.where(item_id: item.id, user_id: user.id).destroy_all

      DiscourseUserCosmetics::Presenter.bump_version!
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
      if item.save
        group_ids = Array(params.dig(:item, :group_ids)).map(&:to_i).reject(&:zero?)
        item.item_groups.destroy_all
        group_ids.uniq.each { |gid| item.item_groups.create!(group_id: gid) }

        save_effect_layers(item) if item.kind == "profile_effect"

        DiscourseUserCosmetics::Presenter.bump_version!
        render json: admin_serialize(item.reload)
      else
        render_json_error(item)
      end
    end

    # İŞTE MUCİZE BURADA: Tüm verileri kusursuz bir şekilde yakalıyoruz!
    def save_effect_layers(item)
      item.effect_layers.destroy_all

      # Rails Strong Parameters (Dizi Koruması) zırhını kaldırıp veriyi saf halinde (unsafe) alıyoruz
      raw_item = params.to_unsafe_h[:item] || {}
      layers = raw_item[:layers] || []
      
      # Ember, dizileri bazen numaralı hash { "0" => {...}, "1" => {...} } olarak gönderir
      layers = layers.values if layers.is_a?(Hash)

      layers.each do |layer|
        # Ember camelCase gönderiyor olabilir, bu yüzden hem snake_case hem camelCase arıyoruz
        anchor = (layer[:anchor] || layer[:Anchor]).to_s.downcase
        stack_order = (layer[:stack_order] || layer[:stackOrder]).to_s.downcase
        
        next unless DiscourseUserCosmetics::EffectLayer::ANCHORS.include?(anchor)
        next unless DiscourseUserCosmetics::EffectLayer::STACK_ORDERS.include?(stack_order)

        # Görsel ID'sini ve linkini her iki isimlendirme formatıyla da kontrol ederek yakalıyoruz
        image_upload_id = (layer[:image_upload_id] || layer[:imageUploadId]).presence
        image_url = (layer[:image_url] || layer[:imageUrl] || layer[:raw_image_url] || layer[:rawImageUrl]).presence
        
        next if image_upload_id.blank? && image_url.blank?

        item.effect_layers.create!(
          anchor: anchor,
          stack_order: stack_order,
          image_upload_id: image_upload_id,
          image_url: image_upload_id.present? ? nil : image_url,
        )
      end
    end

    def admin_serialize(item)
      {
        id: item.id,
        kind: item.kind,
        name: item.name,
        slug: item.slug,
        description: item.description,
        image_url: item.resolved_image_url,
        image_upload_id: item.image_upload_id,
        raw_image_url: item.image_url,
        gradient_from: item.gradient_from,
        gradient_to: item.gradient_to,
        glow_color: item.glow_color,
        rarity_label: item.rarity_label,
        rarity_color: item.rarity_color,
        sort_order: item.sort_order,
        enabled: item.enabled,
        is_default: item.is_default,
        group_ids: item.groups.pluck(:id),
        group_names: item.groups.pluck(:name),
        owner_count: item.user_items.count,
        created_at: item.created_at,
        effect_inner_width: item.resolved_effect_inner_width,
        effect_overflow_top: item.effect_overflow_top || 0,
        effect_overflow_bottom: item.effect_overflow_bottom || 0,
        effect_overflow_horizontal: item.effect_overflow_horizontal || 0,
        layers: item.effect_layers.map { |l| admin_serialize_layer(l) },
      }
    end

    def admin_serialize_layer(layer)
      {
        anchor: layer.anchor,
        stack_order: layer.stack_order,
        image_upload_id: layer.image_upload_id,
        raw_image_url: layer.image_url,
        image_url: layer.resolved_image_url,
      }
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
      )
    end
  end
end