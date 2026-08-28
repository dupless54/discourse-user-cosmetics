# frozen_string_literal: true

module ::DiscourseUserCosmetics
  class ShowcaseService
    FIELD_NAME = "discourse_user_cosmetics_showcase"
    MAX_ITEMS = 6

    class InvalidShowcase < StandardError; end

    class << self
      def item_ids_for(user:)
        return [] unless user

        raw = ::UserCustomField.find_by(user_id: user.id, name: FIELD_NAME)&.value
        normalize_stored_ids(raw)
      end

      def items_for(user:)
        ids = item_ids_for(user: user)
        return [] if ids.empty?

        items =
          DiscourseUserCosmetics::Item
            .enabled
            .where(id: ids)
            .includes(:image_upload, effect_layers: :image_upload)
            .to_a
        items_by_id = items.index_by(&:id)
        candidates =
          ids.filter_map do |id|
            item = items_by_id[id]
            next unless item && DiscourseUserCosmetics::Item.kind_enabled?(item.kind)

            item
          end
        usable_ids =
          DiscourseUserCosmetics::EntitlementResolver.usable_item_ids(
            user: user,
            items: candidates,
          )

        candidates.select { |item| usable_ids.key?(item.id) }
      end

      def serialize_for(user:)
        items_for(user: user).map do |item|
          presentation = DiscourseUserCosmetics::Presenter.serialize_item(item)
          presentation.merge(
            kind: item.kind,
            rarity_label: item.rarity_label,
            rarity_color: item.rarity_color,
          )
        end
      end

      def replace!(user:, item_ids:)
        raise ArgumentError, "user is required" unless user

        ids = normalize_requested_ids(item_ids)
        validate_items!(user: user, ids: ids)

        if ids.empty?
          ::UserCustomField.where(user_id: user.id, name: FIELD_NAME).delete_all
        else
          field = ::UserCustomField.find_or_initialize_by(user_id: user.id, name: FIELD_NAME)
          field.value = ids.to_json
          field.save!
        end

        serialize_for(user: user)
      end

      private

      def normalize_requested_ids(raw_ids)
        source = raw_ids.is_a?(String) ? raw_ids.split(",") : Array(raw_ids)
        ids = source.map { |value| Integer(value, exception: false) }
        raise InvalidShowcase, "invalid cosmetic item id" if ids.any?(&:nil?)

        ids = ids.reject(&:zero?)
        raise InvalidShowcase, "duplicate cosmetic item id" unless ids.uniq.length == ids.length
        raise InvalidShowcase, "too many showcase items" if ids.length > MAX_ITEMS

        ids
      end

      def normalize_stored_ids(raw)
        return [] if raw.blank?

        values = JSON.parse(raw)
        return [] unless values.is_a?(Array)

        values.filter_map { |value| Integer(value, exception: false) }.select(&:positive?).uniq.first(MAX_ITEMS)
      rescue JSON::ParserError
        []
      end

      def validate_items!(user:, ids:)
        return if ids.empty?

        items = DiscourseUserCosmetics::Item.enabled.where(id: ids).to_a
        raise InvalidShowcase, "cosmetic item is unavailable" unless items.length == ids.length
        raise InvalidShowcase, "cosmetic kind is disabled" unless items.all? { |item| DiscourseUserCosmetics::Item.kind_enabled?(item.kind) }

        usable_ids =
          DiscourseUserCosmetics::EntitlementResolver.usable_item_ids(
            user: user,
            items: items,
          )
        raise InvalidShowcase, "cosmetic item is unavailable" unless ids.all? { |id| usable_ids.key?(id) }
      end
    end
  end
end
