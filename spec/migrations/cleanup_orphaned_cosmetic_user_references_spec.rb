# frozen_string_literal: true

require_relative "../../db/migrate/20260827224000_cleanup_orphaned_cosmetic_user_references"

RSpec.describe CleanupOrphanedCosmeticUserReferences do
  before { enable_current_plugin }

  it "removes orphan ownership rows and clears only orphan provenance references" do
    valid_user = Fabricate(:user)
    recipient = Fabricate(:user)
    item = DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: "Repair frame", created_by: valid_user)
    valid_item = DiscourseUserCosmetics::Item.create!(kind: "nameplate", name: "Valid creator plate", created_by: valid_user)
    orphan_user_id = ::User.maximum(:id).to_i + 1_000_000

    valid_selection =
      DiscourseUserCosmetics::UserSelection.create!(
        user: valid_user,
        avatar_frame_item: item,
      )
    valid_grant =
      DiscourseUserCosmetics::UserItem.create!(
        user: valid_user,
        item: item,
        granted_by: valid_user,
      )
    recipient_grant =
      DiscourseUserCosmetics::UserItem.create!(
        user: recipient,
        item: item,
        granted_by: valid_user,
      )

    ActiveRecord::Base.connection.execute(<<~SQL)
      INSERT INTO discourse_user_cosmetics_user_selections
        (user_id, avatar_frame_item_id, created_at, updated_at)
      VALUES
        (#{orphan_user_id}, #{item.id}, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    SQL
    ActiveRecord::Base.connection.execute(<<~SQL)
      INSERT INTO discourse_user_cosmetics_user_items
        (user_id, item_id, granted_by_id, created_at, updated_at)
      VALUES
        (#{orphan_user_id}, #{item.id}, #{valid_user.id}, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    SQL
    recipient_grant.update_columns(granted_by_id: orphan_user_id)
    item.update_columns(created_by_id: orphan_user_id)

    described_class.new.up

    expect(DiscourseUserCosmetics::UserSelection.where(user_id: orphan_user_id)).to be_empty
    expect(DiscourseUserCosmetics::UserItem.where(user_id: orphan_user_id)).to be_empty
    expect(DiscourseUserCosmetics::UserSelection.where(id: valid_selection.id)).to exist
    expect(DiscourseUserCosmetics::UserItem.where(id: valid_grant.id)).to exist
    expect(recipient_grant.reload.granted_by_id).to be_nil
    expect(item.reload.created_by_id).to be_nil
    expect(valid_item.reload.created_by_id).to eq(valid_user.id)
  end
end
