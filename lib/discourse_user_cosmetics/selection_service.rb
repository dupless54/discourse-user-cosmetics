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
      return 0 if item.enabled? && item.usable_by?(user)

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

    def self.publish_selection_change!(user:, kind:)
      MessageBus.publish(CHANGE_CHANNEL, { user_id: user.id, kind: kind })
    end
    private_class_method :publish_selection_change!
  end
end
