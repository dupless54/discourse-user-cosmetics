# frozen_string_literal: true

module ::DiscourseUserCosmetics
  class ItemGroup < ActiveRecord::Base
    self.table_name = "discourse_user_cosmetics_item_groups"

    belongs_to :item, class_name: "DiscourseUserCosmetics::Item"
    belongs_to :group, class_name: "::Group"

    after_create_commit :clear_newly_invalid_selections
    after_update_commit :clear_newly_invalid_selections, if: :saved_change_to_group_id?

    private

    def clear_newly_invalid_selections
      DiscourseUserCosmetics::SelectionService.clear_invalid_for_item!(item)
    end
  end
end
