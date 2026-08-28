# frozen_string_literal: true

class CreateDiscourseUserCosmeticsLoadouts < ActiveRecord::Migration[7.1]
  def change
    create_table :discourse_user_cosmetics_loadouts do |t|
      t.bigint :user_id, null: false
      t.string :name, limit: 80, null: false
      t.bigint :avatar_frame_item_id
      t.bigint :nameplate_item_id
      t.bigint :card_decoration_item_id
      t.bigint :profile_effect_item_id
      t.timestamps null: false
    end

    add_index :discourse_user_cosmetics_loadouts,
              %i[user_id updated_at],
              name: "idx_duc_loadouts_user_updated"
  end
end
