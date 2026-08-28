# frozen_string_literal: true

class AddSideOffsetsToCosmetics < ActiveRecord::Migration[7.0]
  def change
    add_column :discourse_user_cosmetics_items, :effect_side_offset_top, :integer, default: 0, null: false
    add_column :discourse_user_cosmetics_items, :effect_side_offset_bottom, :integer, default: 0, null: false
  end
end
