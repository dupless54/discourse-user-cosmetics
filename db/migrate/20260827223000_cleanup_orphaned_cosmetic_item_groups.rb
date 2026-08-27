# frozen_string_literal: true

class CleanupOrphanedCosmeticItemGroups < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      DELETE FROM discourse_user_cosmetics_item_groups AS item_groups
      WHERE NOT EXISTS (
        SELECT 1
        FROM groups
        WHERE groups.id = item_groups.group_id
      )
    SQL
  end

  # Deleted groups no longer exist, so their restriction rows cannot be
  # reconstructed safely on rollback. This migration only removes invalid
  # references and does not change schema.
  def down
  end
end
