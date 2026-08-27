# frozen_string_literal: true

module ::DiscourseUserCosmetics
  # Computes "what is this user currently wearing" and caches it, so that
  # rendering a post/user-card/profile never has to hit the database for
  # cosmetics on every request. Catalog changes use one global version while
  # user entitlement changes can invalidate only the affected user's cache.
  class Presenter
    CACHE_SCHEMA_VERSION = 3
    CACHE_NAMESPACE = "discourse_user_cosmetics/v#{CACHE_SCHEMA_VERSION}"
    STYLESHEET_KINDS = %w[avatar_frame nameplate].freeze

    def self.cache_version
      Discourse.cache.fetch("#{CACHE_NAMESPACE}/version", expires_in: 30.days) { CACHE_SCHEMA_VERSION }
    end

    def self.bump_version!
      Discourse.cache.write(
        "#{CACHE_NAMESPACE}/version",
        SecureRandom.hex(12),
        expires_in: 30.days,
      )
    end

    def self.user_cache_version(user_id)
      Discourse.cache.fetch("#{CACHE_NAMESPACE}/user-version/#{user_id}", expires_in: 30.days) { CACHE_SCHEMA_VERSION }
    end

    def self.bump_user_version!(user_id)
      return if user_id.blank?

      Discourse.cache.write(
        "#{CACHE_NAMESPACE}/user-version/#{user_id}",
        SecureRandom.hex(12),
        expires_in: 30.days,
      )
    end

    # frames.css is a single public stylesheet shared by all visitors. It needs
    # a version independent from per-user summary caches so a group membership
    # change can invalidate CSS without flushing every user's presentation data.
    def self.stylesheet_version
      Discourse.cache.fetch("#{CACHE_NAMESPACE}/stylesheet-version", expires_in: 30.days) { CACHE_SCHEMA_VERSION }
    end

    def self.bump_stylesheet_version!
      Discourse.cache.write(
        "#{CACHE_NAMESPACE}/stylesheet-version",
        SecureRandom.hex(12),
        expires_in: 30.days,
      )
    end

    def self.invalidate_group_membership!(user_id:, group_id:)
      return if user_id.blank?

      bump_user_version!(user_id)
      return if group_id.blank?

      selection = DiscourseUserCosmetics::UserSelection.find_by(user_id: user_id)
      return unless selection

      selected_stylesheet_item_ids =
        STYLESHEET_KINDS.filter_map do |kind|
          selection.public_send(DiscourseUserCosmetics::UserSelection.field_for(kind))
        end

      return if selected_stylesheet_item_ids.empty?
      return unless DiscourseUserCosmetics::ItemGroup.where(
        group_id: group_id,
        item_id: selected_stylesheet_item_ids,
      ).exists?

      bump_stylesheet_version!
    end

    def self.feature_gate_signature
      DiscourseUserCosmetics::Item::KINDS.map do |kind|
        DiscourseUserCosmetics::Item.kind_enabled?(kind) ? "1" : "0"
      end.join
    end

    def self.summary_for(user)
      return nil unless user

      Discourse.cache.fetch(
        "#{CACHE_NAMESPACE}/summary/#{cache_version}/#{user_cache_version(user.id)}/#{feature_gate_signature}/#{user.id}",
        expires_in: 1.hour,
      ) { build_summary(user) }
    end

    def self.build_summary(user)
      selection = DiscourseUserCosmetics::UserSelection.find_by(user_id: user.id)
      result = {}

      DiscourseUserCosmetics::Item::KINDS.each do |kind|
        result[kind] = nil
        next unless DiscourseUserCosmetics::Item.kind_enabled?(kind)
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
