# frozen_string_literal: true

class ExpandCosmeticRelationIdsToBigint < ActiveRecord::Migration[7.1]
  def up
    # Rails 7 / current Discourse tables use bigint primary keys. These columns
    # reference either Discourse records or plugin records whose ids can exceed
    # the 32-bit integer range, so widen them losslessly before the upload-ref
    # backfill runs.
    change_column :discourse_user_cosmetics_items, :image_upload_id, :bigint
    change_column :discourse_user_cosmetics_items, :created_by_id, :bigint

    change_column :discourse_user_cosmetics_item_groups, :item_id, :bigint
    change_column :discourse_user_cosmetics_item_groups, :group_id, :bigint

    change_column :discourse_user_cosmetics_user_items, :user_id, :bigint
    change_column :discourse_user_cosmetics_user_items, :item_id, :bigint
    change_column :discourse_user_cosmetics_user_items, :granted_by_id, :bigint

    change_column :discourse_user_cosmetics_user_selections, :user_id, :bigint
    change_column :discourse_user_cosmetics_user_selections, :avatar_frame_item_id, :bigint
    change_column :discourse_user_cosmetics_user_selections, :nameplate_item_id, :bigint
    change_column :discourse_user_cosmetics_user_selections, :card_decoration_item_id, :bigint
    change_column :discourse_user_cosmetics_user_selections, :profile_effect_item_id, :bigint

    change_column :discourse_user_cosmetics_effect_layers, :item_id, :bigint
    change_column :discourse_user_cosmetics_effect_layers, :image_upload_id, :bigint
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          "Narrowing cosmetic relation IDs back to 32-bit integers could truncate valid records"
  end
end
