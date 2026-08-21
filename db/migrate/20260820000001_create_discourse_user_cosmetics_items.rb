# frozen_string_literal: true

class CreateDiscourseUserCosmeticsItems < ActiveRecord::Migration[7.1]
  def change
    create_table :discourse_user_cosmetics_items do |t|
      t.string :kind, null: false, limit: 30 # avatar_frame | nameplate | card_decoration
      t.string :name, null: false, limit: 100
      t.string :slug, null: false, limit: 120
      t.text :description

      # Visual: either an uploaded/linked image, and/or a two-color gradient,
      # and/or a glow accent color. A kind decides which of these it actually uses.
      t.integer :image_upload_id
      t.string :image_url, limit: 1000
      t.string :gradient_from, limit: 20
      t.string :gradient_to, limit: 20
      t.string :glow_color, limit: 20

      # Purely cosmetic "rarity" flavor text, shown as a little pill in the picker.
      t.string :rarity_label, limit: 40
      t.string :rarity_color, limit: 20

      t.integer :sort_order, null: false, default: 0
      t.boolean :enabled, null: false, default: true
      # is_default items are automatically usable by every user (no unlock needed).
      t.boolean :is_default, null: false, default: false

      t.integer :created_by_id

      t.timestamps null: false
    end

    add_index :discourse_user_cosmetics_items, %i[kind enabled sort_order],
              name: "idx_duc_items_kind_enabled_sort"
    add_index :discourse_user_cosmetics_items, %i[kind slug], unique: true, name: "idx_duc_items_kind_slug"
  end
end
