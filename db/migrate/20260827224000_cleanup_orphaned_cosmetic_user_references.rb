# frozen_string_literal: true

class CleanupOrphanedCosmeticUserReferences < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      DELETE FROM discourse_user_cosmetics_user_selections AS selections
      WHERE NOT EXISTS (
        SELECT 1
        FROM users
        WHERE users.id = selections.user_id
      )
    SQL

    execute <<~SQL
      DELETE FROM discourse_user_cosmetics_user_items AS user_items
      WHERE NOT EXISTS (
        SELECT 1
        FROM users
        WHERE users.id = user_items.user_id
      )
    SQL

    execute <<~SQL
      UPDATE discourse_user_cosmetics_user_items AS user_items
      SET granted_by_id = NULL,
          updated_at = CURRENT_TIMESTAMP
      WHERE granted_by_id IS NOT NULL
        AND NOT EXISTS (
          SELECT 1
          FROM users
          WHERE users.id = user_items.granted_by_id
        )
    SQL

    execute <<~SQL
      UPDATE discourse_user_cosmetics_items AS items
      SET created_by_id = NULL,
          updated_at = CURRENT_TIMESTAMP
      WHERE created_by_id IS NOT NULL
        AND NOT EXISTS (
          SELECT 1
          FROM users
          WHERE users.id = items.created_by_id
        )
    SQL
  end

  # Deleted users cannot be reconstructed safely, so removed ownership rows and
  # cleared provenance identifiers are intentionally non-reversible.
  def down
  end
end
