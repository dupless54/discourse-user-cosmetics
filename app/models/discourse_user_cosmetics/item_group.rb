# frozen_string_literal: true

module ::DiscourseUserCosmetics
  class ItemGroup < ActiveRecord::Base
    self.table_name = "discourse_user_cosmetics_item_groups"

    belongs_to :item, class_name: "DiscourseUserCosmetics::Item"
    belongs_to :group, class_name: "::Group"
  end
end
