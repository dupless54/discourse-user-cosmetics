# frozen_string_literal: true

RSpec.describe DiscourseUserCosmetics::Presenter do
  fab!(:user)

  before { enable_current_plugin }

  it "omits a cached selected cosmetic immediately when its kind is disabled" do
    item = DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: "Feature gated frame")

    DiscourseUserCosmetics::SelectionService.select!(
      user: user,
      kind: "avatar_frame",
      item_id: item.id,
    )

    expect(described_class.summary_for(user)["avatar_frame"]).to include(id: item.id)

    SiteSetting.discourse_user_cosmetics_avatar_frames_enabled = false

    expect(described_class.summary_for(user)["avatar_frame"]).to be_nil
  end

  it "keeps the stored selection while a kind is disabled" do
    item = DiscourseUserCosmetics::Item.create!(kind: "nameplate", name: "Temporarily hidden plate")

    DiscourseUserCosmetics::SelectionService.select!(
      user: user,
      kind: "nameplate",
      item_id: item.id,
    )

    SiteSetting.discourse_user_cosmetics_nameplates_enabled = false

    expect(described_class.summary_for(user)["nameplate"]).to be_nil
    expect(
      DiscourseUserCosmetics::UserSelection.find_by!(user_id: user.id).nameplate_item_id,
    ).to eq(item.id)

    SiteSetting.discourse_user_cosmetics_nameplates_enabled = true

    expect(described_class.summary_for(user)["nameplate"]).to include(id: item.id)
  end

  it "invalidates cached group entitlement when membership is removed or restored" do
    group = Fabricate(:group)
    group.add(user)
    item = DiscourseUserCosmetics::Item.create!(kind: "card_decoration", name: "Group card")
    item.item_groups.create!(group: group)

    DiscourseUserCosmetics::SelectionService.select!(
      user: user,
      kind: "card_decoration",
      item_id: item.id,
    )

    expect(described_class.summary_for(user)["card_decoration"]).to include(id: item.id)

    group.remove(user)

    expect(described_class.summary_for(user)["card_decoration"]).to be_nil
    expect(
      DiscourseUserCosmetics::UserSelection.find_by!(user_id: user.id).card_decoration_item_id,
    ).to eq(item.id)

    group.add(user)

    expect(described_class.summary_for(user)["card_decoration"]).to include(id: item.id)
  end
end
