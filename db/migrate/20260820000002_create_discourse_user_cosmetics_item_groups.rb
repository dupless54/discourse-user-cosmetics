# frozen_string_literal: true

class CreateDiscourseUserCosmeticsItemGroups < ActiveRecord::Migration[7.1]
  def change
    create_table :discourse_user_cosmetics_item_groups do |t|
      t.integer :item_id, null: false
      t.integer :group_id, null: false
      t.timestamps null: false
    end

    add_index :discourse_user_cosmetics_item_groups, %i[item_id group_id], unique: true,
              name: "idx_duc_item_groups_item_group"
    add_index :discourse_user_cosmetics_item_groups, :group_id, name: "idx_duc_item_groups_group"
  end
end
