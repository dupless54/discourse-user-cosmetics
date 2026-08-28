# frozen_string_literal: true

RSpec.describe DiscourseUserCosmetics::EntitlementResolver do
  fab!(:user)

  it "honors an extended item access rule that restricts base access" do
    item = DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: "Store locked frame")
    item.define_singleton_method(:usable_by?) { |_candidate| false }

    usable = described_class.usable_item_ids(user: user, items: [item])

    expect(usable).not_to have_key(item.id)
  end

  it "honors an extended item access rule that grants access" do
    restricted_group = Fabricate(:group)
    item = DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: "Extended frame")
    item.item_groups.create!(group: restricted_group)
    allowed_user_id = user.id
    item.define_singleton_method(:usable_by?) { |candidate| candidate.id == allowed_user_id }

    usable = described_class.usable_item_ids(user: user, items: [item])

    expect(usable).to include(item.id => true)
  end
end
