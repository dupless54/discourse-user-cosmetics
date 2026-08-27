# frozen_string_literal: true

class BackfillCosmeticUploadReferences < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      INSERT INTO upload_references (upload_id, target_type, target_id, created_at, updated_at)
      SELECT items.image_upload_id,
             'DiscourseUserCosmetics::Item',
             items.id,
             CURRENT_TIMESTAMP,
             CURRENT_TIMESTAMP
      FROM discourse_user_cosmetics_items AS items
      INNER JOIN uploads ON uploads.id = items.image_upload_id
      WHERE items.image_upload_id IS NOT NULL
      ON CONFLICT DO NOTHING
    SQL

    execute <<~SQL
      INSERT INTO upload_references (upload_id, target_type, target_id, created_at, updated_at)
      SELECT layers.image_upload_id,
             'DiscourseUserCosmetics::EffectLayer',
             layers.id,
             CURRENT_TIMESTAMP,
             CURRENT_TIMESTAMP
      FROM discourse_user_cosmetics_effect_layers AS layers
      INNER JOIN uploads ON uploads.id = layers.image_upload_id
      WHERE layers.image_upload_id IS NOT NULL
      ON CONFLICT DO NOTHING
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          "Upload references may have changed after this backfill and cannot be safely distinguished"
  end
end
