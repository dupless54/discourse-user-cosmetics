# frozen_string_literal: true

module ::DiscourseUserCosmetics
  class UserItem < ActiveRecord::Base
    self.table_name = "discourse_user_cosmetics_user_items"

    belongs_to :user, class_name: "::User"
    belongs_to :item, class_name: "DiscourseUserCosmetics::Item"
    belongs_to :granted_by, class_name: "::User", optional: true
  end
end
