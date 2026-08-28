# frozen_string_literal: true

module ::DiscourseUserCosmetics
  class ItemGroup < ActiveRecord::Base
    self.table_name = "discourse_user_cosmetics_item_groups"

    belongs_to :item, class_name: "DiscourseUserCosmetics::Item"
    belongs_to :group, class_name: "::Group"
  end
end

# == Schema Information
#
# Table name: discourse_user_cosmetics_item_groups
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  group_id   :bigint           not null
#  item_id    :bigint           not null
#
# Indexes
#
#  idx_duc_item_groups_group       (group_id)
#  idx_duc_item_groups_item_group  (item_id,group_id) UNIQUE
#
