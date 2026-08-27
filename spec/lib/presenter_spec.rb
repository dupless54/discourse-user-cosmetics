# frozen_string_literal: true

RSpec.describe DiscourseUserCosmetics::Presenter do
  fab!(:user)

  before { enable_current_plugin }

  it "omits a selected cosmetic from public presentation when its kind is disabled" do
    item = DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: "Feature gated frame")

    DiscourseUserCosmetics::SelectionService.select!(
      user: user,
      kind: "avatar_frame",
      item_id: item.id,
    )

    expect(described_class.build_summary(user)["avatar_frame"]).to include(id: item.id)

    SiteSetting.discourse_user_cosmetics_avatar_frames_enabled = false

    expect(described_class.build_summary(user)["avatar_frame"]).to be_nil
  end

  it "keeps the stored selection while a kind is disabled" do
    item = DiscourseUserCosmetics::Item.create!(kind: "nameplate", name: "Temporarily hidden plate")

    DiscourseUserCosmetics::SelectionService.select!(
      user: user,
      kind: "nameplate",
      item_id: item.id,
    )

    SiteSetting.discourse_user_cosmetics_nameplates_enabled = false

    expect(described_class.build_summary(user)["nameplate"]).to be_nil
    expect(
      DiscourseUserCosmetics::UserSelection.find_by!(user_id: user.id).nameplate_item_id,
    ).to eq(item.id)

    SiteSetting.discourse_user_cosmetics_nameplates_enabled = true

    expect(described_class.build_summary(user)["nameplate"]).to include(id: item.id)
  end
end
