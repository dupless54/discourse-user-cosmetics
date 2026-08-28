# frozen_string_literal: true

RSpec.describe DiscourseUserCosmetics::ItemGroup do
  before { enable_current_plugin }

  it "removes the deleted group's restriction and invalidates presentation caches" do
    group = Fabricate(:group)
    item = DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: "Deleted group frame")
    item.item_groups.create!(group: group)

    previous_version = DiscourseUserCosmetics::Presenter.cache_version
    group_id = group.id

    group.destroy!

    expect(DiscourseUserCosmetics::ItemGroup.where(group_id: group_id)).to be_empty
    expect(item.reload.public_access?).to eq(true)
    expect(DiscourseUserCosmetics::Presenter.cache_version).not_to eq(previous_version)
  end

  it "preserves restrictions belonging to groups that still exist" do
    deleted_group = Fabricate(:group)
    remaining_group = Fabricate(:group)
    item = DiscourseUserCosmetics::Item.create!(kind: "nameplate", name: "Multi-group plate")
    item.item_groups.create!(group: deleted_group)
    item.item_groups.create!(group: remaining_group)

    deleted_group.destroy!

    expect(item.item_groups.reload.pluck(:group_id)).to eq([remaining_group.id])
    expect(item.public_access?).to eq(false)
  end
end
