# frozen_string_literal: true

class CreateDiscourseUserCosmeticsUserItems < ActiveRecord::Migration[7.1]
  def change
    create_table :discourse_user_cosmetics_user_items do |t|
      t.integer :user_id, null: false
      t.integer :item_id, null: false
      t.integer :granted_by_id
      t.timestamps null: false
    end

    add_index :discourse_user_cosmetics_user_items, %i[user_id item_id], unique: true,
              name: "idx_duc_user_items_user_item"
    add_index :discourse_user_cosmetics_user_items, :item_id, name: "idx_duc_user_items_item"
  end
end
