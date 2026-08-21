# frozen_string_literal: true

class CreateDiscourseUserCosmeticsUserSelections < ActiveRecord::Migration[7.1]
  def change
    create_table :discourse_user_cosmetics_user_selections do |t|
      t.integer :user_id, null: false
      t.integer :avatar_frame_item_id
      t.integer :nameplate_item_id
      t.integer :card_decoration_item_id
      t.timestamps null: false
    end

    add_index :discourse_user_cosmetics_user_selections, :user_id, unique: true,
              name: "idx_duc_user_selections_user"
  end
end
