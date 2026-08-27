# frozen_string_literal: true

module ::DiscourseUserCosmetics
  class SelectionService
    def self.select!(user:, kind:, item_id:)
      kind = kind.to_s
      raise Discourse::InvalidParameters.new(:kind) unless DiscourseUserCosmetics::Item::KINDS.include?(kind)

      item = nil
      if item_id.present?
        item = DiscourseUserCosmetics::Item.find_by(id: item_id, kind: kind, enabled: true)
        raise Discourse::NotFound unless item
        raise Discourse::InvalidAccess unless item.usable_by?(user)
      end

      selection = DiscourseUserCosmetics::UserSelection.find_or_initialize_by(user_id: user.id)
      selection.public_send("#{DiscourseUserCosmetics::UserSelection.field_for(kind)}=", item&.id)
      selection.save!

      DiscourseUserCosmetics::Presenter.bump_version!
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

      DiscourseUserCosmetics::Presenter.bump_version! if bump && changed.positive?
      changed
    end

    def self.clear_invalid_for_item!(item, bump: true)
      field = DiscourseUserCosmetics::UserSelection.field_for(item.kind)
      changed = 0

      DiscourseUserCosmetics::UserSelection.where(field => item.id).includes(:user).find_each do |selection|
        user = selection.user
        next if user && item.enabled? && item.usable_by?(user)

        selection.update_columns(field => nil, updated_at: Time.zone.now)
        changed += 1
      end

      DiscourseUserCosmetics::Presenter.bump_version! if bump && changed.positive?
      changed
    end
  end
end
