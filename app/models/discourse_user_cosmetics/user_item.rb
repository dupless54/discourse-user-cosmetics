# frozen_string_literal: true

module ::DiscourseUserCosmetics
  class UserItem < ActiveRecord::Base
    self.table_name = "discourse_user_cosmetics_user_items"

    belongs_to :user, class_name: "::User"
    belongs_to :item, class_name: "DiscourseUserCosmetics::Item"
    belongs_to :granted_by, class_name: "::User", optional: true

    after_destroy :clear_unusable_active_selection

    private

    def clear_unusable_active_selection
      DiscourseUserCosmetics::SelectionService.clear_item_for_user_if_unusable!(item: item, user: user)
    end
  end
end
