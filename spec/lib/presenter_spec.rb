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

  it "targets non-stylesheet selection invalidation to the selected user" do
    other_user = Fabricate(:user)
    item = DiscourseUserCosmetics::Item.create!(kind: "card_decoration", name: "Targeted card")

    global_version = described_class.cache_version
    user_version = described_class.user_cache_version(user.id)
    other_user_version = described_class.user_cache_version(other_user.id)
    stylesheet_version = described_class.stylesheet_version

    DiscourseUserCosmetics::SelectionService.select!(
      user: user,
      kind: "card_decoration",
      item_id: item.id,
    )

    expect(described_class.cache_version).to eq(global_version)
    expect(described_class.user_cache_version(user.id)).not_to eq(user_version)
    expect(described_class.user_cache_version(other_user.id)).to eq(other_user_version)
    expect(described_class.stylesheet_version).to eq(stylesheet_version)
    expect(described_class.summary_for(user)["card_decoration"]).to include(id: item.id)
  end

  it "invalidates only the selected user and shared stylesheet for CSS-backed selections" do
    item =
      DiscourseUserCosmetics::Item.create!(
        kind: "avatar_frame",
        name: "Targeted frame",
        image_url: "https://example.com/targeted-frame.webp",
      )

    global_version = described_class.cache_version
    user_version = described_class.user_cache_version(user.id)
    stylesheet_version = described_class.stylesheet_version

    DiscourseUserCosmetics::SelectionService.select!(
      user: user,
      kind: "avatar_frame",
      item_id: item.id,
    )

    expect(described_class.cache_version).to eq(global_version)
    expect(described_class.user_cache_version(user.id)).not_to eq(user_version)
    expect(described_class.stylesheet_version).not_to eq(stylesheet_version)

    stable_user_version = described_class.user_cache_version(user.id)
    stable_stylesheet_version = described_class.stylesheet_version

    DiscourseUserCosmetics::SelectionService.select!(
      user: user,
      kind: "avatar_frame",
      item_id: item.id,
    )

    expect(described_class.cache_version).to eq(global_version)
    expect(described_class.user_cache_version(user.id)).to eq(stable_user_version)
    expect(described_class.stylesheet_version).to eq(stable_stylesheet_version)
  end

  it "targets cache invalidation when one user's selected item becomes unusable" do
    item =
      DiscourseUserCosmetics::Item.create!(
        kind: "nameplate",
        name: "Restricted later",
        gradient_from: "#112233",
        gradient_to: "#445566",
      )
    DiscourseUserCosmetics::SelectionService.select!(
      user: user,
      kind: "nameplate",
      item_id: item.id,
    )

    denied_group = Fabricate(:group)
    item.item_groups.create!(group: denied_group)

    global_version = described_class.cache_version
    user_version = described_class.user_cache_version(user.id)
    stylesheet_version = described_class.stylesheet_version

    changed =
      DiscourseUserCosmetics::SelectionService.clear_item_for_user_if_unusable!(
        item: item,
        user: user,
      )

    expect(changed).to eq(1)
    expect(described_class.cache_version).to eq(global_version)
    expect(described_class.user_cache_version(user.id)).not_to eq(user_version)
    expect(described_class.stylesheet_version).not_to eq(stylesheet_version)
    expect(
      DiscourseUserCosmetics::UserSelection.find_by!(user_id: user.id).nameplate_item_id,
    ).to be_nil
  end
end
