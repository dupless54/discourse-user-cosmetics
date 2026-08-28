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

# == Schema Information
#
# Table name: discourse_user_cosmetics_user_items
#
#  id            :bigint           not null, primary key
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  granted_by_id :bigint
#  item_id       :bigint           not null
#  user_id       :bigint           not null
#
# Indexes
#
#  idx_duc_user_items_item       (item_id)
#  idx_duc_user_items_user_item  (user_id,item_id) UNIQUE
#
