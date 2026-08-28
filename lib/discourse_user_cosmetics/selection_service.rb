# frozen_string_literal: true

module ::DiscourseUserCosmetics
  class SelectionService
    CHANGE_CHANNEL = "/user-cosmetics/changes"

    def self.select!(user:, kind:, item_id:)
      kind = kind.to_s
      raise Discourse::InvalidParameters.new(:kind) if DiscourseUserCosmetics::Item::KINDS.exclude?(kind)

      item = nil
      if item_id.present?
        raise Discourse::InvalidAccess unless DiscourseUserCosmetics::Item.kind_enabled?(kind)

        item = DiscourseUserCosmetics::Item.find_by(id: item_id, kind: kind, enabled: true)
        raise Discourse::NotFound unless item

        usable_item_ids =
          DiscourseUserCosmetics::EntitlementResolver.usable_item_ids(
            user: user,
            items: [item],
          )
        raise Discourse::InvalidAccess unless usable_item_ids.key?(item.id)
      end

      field = DiscourseUserCosmetics::UserSelection.field_for(kind)
      selection = DiscourseUserCosmetics::UserSelection.find_or_initialize_by(user_id: user.id)
      selection.public_send("#{field}=", item&.id)
      changed = selection.will_save_change_to_attribute?(field)
      selection.save!

      if changed
        DiscourseUserCosmetics::Presenter.invalidate_user_selection!(
          user_id: user.id,
          kind: kind,
        )
        publish_selection_change!(user: user, kind: kind)
      end

      selection
    end

    # Replaces all cosmetic slots in one database write. Every non-empty slot
    # is resolved and entitlement-checked before the selection row is changed,
    # so an unavailable item cannot produce a partially applied loadout.
    def self.replace_all!(user:, selections:)
      raise ArgumentError, "user is required" unless user

      normalized = normalize_complete_selections(selections)
      validate_complete_selections!(user: user, selections: normalized)

      selection = DiscourseUserCosmetics::UserSelection.find_or_create_by!(user_id: user.id)
      changed_kinds = []

      selection.with_lock do
        normalized.each do |kind, item_id|
          field = DiscourseUserCosmetics::UserSelection.field_for(kind)
          selection.public_send("#{field}=", item_id)
          changed_kinds << kind if selection.will_save_change_to_attribute?(field)
        end
        selection.save!
      end

      changed_kinds.each do |kind|
        DiscourseUserCosmetics::Presenter.invalidate_user_selection!(
          user_id: user.id,
          kind: kind,
        )
        publish_selection_change!(user: user, kind: kind)
      end

      selection
    end

    def self.clear_item!(item, bump: true)
      field = DiscourseUserCosmetics::UserSelection.field_for(item.kind)
      changed =
        DiscourseUserCosmetics::UserSelection.where(field => item.id).update_all(
          field => nil,
          updated_at: Time.zone.now,
        )

      DiscourseUserCosmetics::Presenter.bump_version! if bump && changed.positive?
      changed
    end

    def self.clear_item_for_user_if_unusable!(item:, user:, bump: true)
      entitled =
        item.enabled? &&
          DiscourseUserCosmetics::EntitlementResolver
            .usable_item_ids(user: user, items: [item])
            .key?(item.id)
      return 0 if entitled

      field = DiscourseUserCosmetics::UserSelection.field_for(item.kind)
      changed =
        DiscourseUserCosmetics::UserSelection.where(user_id: user.id, field => item.id).update_all(
          field => nil,
          updated_at: Time.zone.now,
        )

      if bump && changed.positive?
        DiscourseUserCosmetics::Presenter.invalidate_user_selection!(
          user_id: user.id,
          kind: item.kind,
        )
      end
      changed
    end

    def self.clear_invalid_for_item!(item, bump: true)
      field = DiscourseUserCosmetics::UserSelection.field_for(item.kind)
      selections = DiscourseUserCosmetics::UserSelection.where(field => item.id)

      changed =
        if item.enabled?
          if item.is_default? || item.public_access?
            0
          else
            group_user_ids =
              ::GroupUser.where(group_id: item.item_groups.select(:group_id)).select(:user_id)
            direct_user_ids =
              DiscourseUserCosmetics::UserItem.where(item_id: item.id).select(:user_id)

            selections
              .where.not(user_id: group_user_ids)
              .where.not(user_id: direct_user_ids)
              .update_all(field => nil, updated_at: Time.zone.now)
          end
        else
          selections.update_all(field => nil, updated_at: Time.zone.now)
        end

      DiscourseUserCosmetics::Presenter.bump_version! if bump && changed.positive?
      changed
    end

    def self.normalize_complete_selections(selections)
      unless selections.respond_to?(:to_h)
        raise Discourse::InvalidParameters.new(:selections)
      end

      normalized_keys = selections.to_h.transform_keys(&:to_s)
      if normalized_keys.keys.sort != DiscourseUserCosmetics::Item::KINDS.sort
        raise Discourse::InvalidParameters.new(:selections)
      end

      normalized_keys.transform_values { |item_id| normalize_item_id(item_id) }
    end
    private_class_method :normalize_complete_selections

    def self.normalize_item_id(item_id)
      return nil if item_id.blank?

      normalized = Integer(item_id, exception: false)
      raise Discourse::InvalidParameters.new(:item_id) unless normalized&.positive?

      normalized
    end
    private_class_method :normalize_item_id

    def self.validate_complete_selections!(user:, selections:)
      requested_ids = selections.values.compact.uniq
      items =
        if requested_ids.empty?
          []
        else
          DiscourseUserCosmetics::Item.enabled.where(id: requested_ids).to_a
        end
      items_by_id = items.index_by(&:id)

      selections.each do |kind, item_id|
        next if item_id.blank?
        raise Discourse::InvalidAccess unless DiscourseUserCosmetics::Item.kind_enabled?(kind)

        item = items_by_id[item_id]
        raise Discourse::NotFound unless item&.kind == kind
      end

      usable_item_ids =
        DiscourseUserCosmetics::EntitlementResolver.usable_item_ids(
          user: user,
          items: items,
        )

      selections.each_value do |item_id|
        next if item_id.blank?
        raise Discourse::InvalidAccess unless usable_item_ids.key?(item_id)
      end
    end
    private_class_method :validate_complete_selections!

    def self.publish_selection_change!(user:, kind:)
      MessageBus.publish(CHANGE_CHANNEL, { user_id: user.id, kind: kind })
    end
    private_class_method :publish_selection_change!
  end
end
