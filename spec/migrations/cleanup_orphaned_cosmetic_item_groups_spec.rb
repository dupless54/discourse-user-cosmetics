# frozen_string_literal: true

require_relative "../../db/migrate/20260828000000_cleanup_orphaned_cosmetic_item_groups"

RSpec.describe CleanupOrphanedCosmeticItemGroups do
  before { enable_current_plugin }

  it "removes only item-group rows whose Discourse group no longer exists" do
    item = DiscourseUserCosmetics::Item.create!(kind: "card_decoration", name: "Repair card")
    valid_group = Fabricate(:group)
    valid_link = item.item_groups.create!(group: valid_group)
    orphan_group_id = ::Group.maximum(:id).to_i + 1_000_000

    ActiveRecord::Base.connection.execute(<<~SQL)
      INSERT INTO discourse_user_cosmetics_item_groups (item_id, group_id, created_at, updated_at)
      VALUES (#{item.id}, #{orphan_group_id}, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    SQL

    described_class.new.up

    expect(DiscourseUserCosmetics::ItemGroup.where(id: valid_link.id)).to exist
    expect(DiscourseUserCosmetics::ItemGroup.where(group_id: orphan_group_id)).to be_empty
  end
end
