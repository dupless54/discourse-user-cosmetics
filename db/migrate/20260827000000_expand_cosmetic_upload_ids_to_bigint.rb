# frozen_string_literal: true

class ExpandCosmeticUploadIdsToBigint < ActiveRecord::Migration[7.1]
  def up
    # Discourse Upload IDs are bigint-capable. Keep our foreign-key-like columns
    # wide enough to store every valid Upload#id before creating references.
    change_column :discourse_user_cosmetics_items, :image_upload_id, :bigint
    change_column :discourse_user_cosmetics_effect_layers, :image_upload_id, :bigint
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          "Narrowing cosmetic upload IDs back to 32-bit integers could truncate valid Upload IDs"
  end
end
