# frozen_string_literal: true

module ::DiscourseUserCosmetics
  # Computes "what is this user currently wearing" and caches it, so that
  # rendering a post/user-card/profile never has to hit the database for
  # cosmetics on every request. The cache is invalidated instantly (for
  # every user at once) by bumping a single version counter, which is far
  # cheaper and safer than trying to enumerate affected users on every edit.
  class Presenter
    CACHE_NAMESPACE = "discourse_user_cosmetics"

    def self.cache_version
      Discourse.cache.fetch("#{CACHE_NAMESPACE}/version", expires_in: 30.days) { 1 }
    end

    def self.bump_version!
      current = Discourse.cache.read("#{CACHE_NAMESPACE}/version") || 1
      Discourse.cache.write("#{CACHE_NAMESPACE}/version", current + 1, expires_in: 30.days)
    end

    def self.summary_for(user)
      return nil unless user
      Discourse.cache.fetch("#{CACHE_NAMESPACE}/summary/#{cache_version}/#{user.id}", expires_in: 1.hour) do
        build_summary(user)
      end
    end

    def self.build_summary(user)
      selection = DiscourseUserCosmetics::UserSelection.find_by(user_id: user.id)
      result = {}

      DiscourseUserCosmetics::Item::KINDS.each do |kind|
        result[kind] = nil
        next if kind == "profile_effect" && !SiteSetting.discourse_user_cosmetics_profile_effects_enabled
        next unless selection
        item_id = selection.public_send(DiscourseUserCosmetics::UserSelection.field_for(kind))
        next unless item_id

        item = DiscourseUserCosmetics::Item.find_by(id: item_id, kind: kind, enabled: true)
        next unless item
        next unless item.usable_by?(user)

        result[kind] = serialize_item(item)
      end

      result
    end

    def self.serialize_item(item)
      base = {
        id: item.id,
        slug: item.slug,
        name: item.name,
        image_url: item.resolved_image_url,
        gradient_from: item.gradient_from,
        gradient_to: item.gradient_to,
        glow_color: item.glow_color,
      }

      base.merge!(effect_fields(item)) if item.kind == "profile_effect"
      base
    end

    # Profile effects are serialized as positioned layers plus the reference
    # geometry used by the client to scale overflow and side clipping values.
    def self.effect_fields(item)
      layers =
        item
          .effect_layers
          .map { |layer| { anchor: layer.anchor, stack_order: layer.stack_order, image_url: layer.resolved_image_url } }
          .select { |layer| layer[:image_url].present? }

      representative =
        layers.find { |layer| layer[:anchor] == "top" && layer[:stack_order] == "front" } || layers.first

      {
        image_url: representative && representative[:image_url],
        inner_width: item.resolved_effect_inner_width,
        overflow_top: item.effect_overflow_top || 0,
        overflow_bottom: item.effect_overflow_bottom || 0,
        overflow_horizontal: item.effect_overflow_horizontal || 0,
        effect_side_offset_top: item.effect_side_offset_top || 0,
        effect_side_offset_bottom: item.effect_side_offset_bottom || 0,
        layers: layers,
      }
    end
  end
end
