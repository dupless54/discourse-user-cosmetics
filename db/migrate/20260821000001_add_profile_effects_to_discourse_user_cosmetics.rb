# frozen_string_literal: true

class AddProfileEffectsToDiscourseUserCosmetics < ActiveRecord::Migration[7.1]
  def change
    # Discord'un "profil efekti" JSON şemasındaki items[0] alanlarının karşılığı:
    # inner_width, overflow_top, overflow_bottom, overflow_horizontal.
    # Sadece kind == "profile_effect" olan öğelerde anlamlıdır.
    add_column :discourse_user_cosmetics_items, :effect_inner_width, :integer
    add_column :discourse_user_cosmetics_items, :effect_overflow_top, :integer
    add_column :discourse_user_cosmetics_items, :effect_overflow_bottom, :integer
    add_column :discourse_user_cosmetics_items, :effect_overflow_horizontal, :integer

    add_column :discourse_user_cosmetics_user_selections, :profile_effect_item_id, :integer

    # Discord JSON'daki "layers" dizisinin karşılığı. Her katman:
    #   anchor       -> "top" | "bottom"   (JSON: layers[].anchor)
    #   stack_order  -> "front" | "back"   (JSON: layers[].order)
    # Böylece bir öğe en fazla 4 katman taşır: üst-ön, üst-arka, alt-ön, alt-arka.
    create_table :discourse_user_cosmetics_effect_layers do |t|
      t.integer :item_id, null: false
      t.string :anchor, null: false, limit: 10
      t.string :stack_order, null: false, limit: 10
      t.integer :image_upload_id
      t.string :image_url, limit: 1000
      t.timestamps null: false
    end

    add_index :discourse_user_cosmetics_effect_layers, %i[item_id anchor stack_order], unique: true,
              name: "idx_duc_effect_layers_item_anchor_order"
  end
end
