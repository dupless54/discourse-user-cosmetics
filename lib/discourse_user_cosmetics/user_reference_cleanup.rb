# frozen_string_literal: true

module ::DiscourseUserCosmetics
  class UserReferenceCleanup
    STYLESHEET_SELECTION_FIELDS = %i[avatar_frame_item_id nameplate_item_id].freeze

    def self.cleanup!(user_id:)
      return if user_id.blank?

      stylesheet_selection =
        DiscourseUserCosmetics::UserSelection.where(user_id: user_id).pick(*STYLESHEET_SELECTION_FIELDS)
      had_stylesheet_selection = stylesheet_selection&.any?(&:present?)

      selections_deleted = DiscourseUserCosmetics::UserSelection.where(user_id: user_id).delete_all
      owned_grants_deleted = DiscourseUserCosmetics::UserItem.where(user_id: user_id).delete_all
      grant_provenance_cleared =
        DiscourseUserCosmetics::UserItem.where(granted_by_id: user_id).update_all(
          granted_by_id: nil,
          updated_at: Time.zone.now,
        )
      item_provenance_cleared =
        DiscourseUserCosmetics::Item.where(created_by_id: user_id).update_all(
          created_by_id: nil,
          updated_at: Time.zone.now,
        )

      DiscourseUserCosmetics::Presenter.bump_stylesheet_version! if had_stylesheet_selection

      {
        selections_deleted: selections_deleted,
        owned_grants_deleted: owned_grants_deleted,
        grant_provenance_cleared: grant_provenance_cleared,
        item_provenance_cleared: item_provenance_cleared,
      }
    end
  end
end
