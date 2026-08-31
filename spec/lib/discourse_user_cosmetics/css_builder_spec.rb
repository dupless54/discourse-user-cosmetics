# frozen_string_literal: true

RSpec.describe DiscourseUserCosmetics::CssBuilder do
  before { enable_current_plugin }

  it "keeps stylesheet query count constant as selected users grow within a batch" do
    item =
      DiscourseUserCosmetics::Item.create!(
        kind: "avatar_frame",
        name: "Shared frame",
        image_url: "https://example.com/shared-frame.webp",
      )

    users = Array.new(2) { Fabricate(:user) }
    users.each do |user|
      DiscourseUserCosmetics::SelectionService.select!(
        user: user,
        kind: "avatar_frame",
        item_id: item.id,
      )
    end

    small_queries = track_sql_queries { described_class.build_frames_css }

    additional_users = Array.new(18) { Fabricate(:user) }
    additional_users.each do |user|
      DiscourseUserCosmetics::SelectionService.select!(
        user: user,
        kind: "avatar_frame",
        item_id: item.id,
      )
    end

    large_css = nil
    large_queries = track_sql_queries { large_css = described_class.build_frames_css }

    expect(large_queries.size).to eq(small_queries.size)
    expect(large_css).to include("duc-avatar-frame-user-#{users.first.id}")
    expect(large_css).to include("duc-avatar-frame-user-#{additional_users.last.id}")
  end

  it "preserves group and direct-grant entitlement filtering in the bulk query" do
    item =
      DiscourseUserCosmetics::Item.create!(
        kind: "avatar_frame",
        name: "Restricted frame",
        image_url: "https://example.com/restricted-frame.webp",
      )

    group_user = Fabricate(:user)
    direct_user = Fabricate(:user)
    stale_user = Fabricate(:user)

    [group_user, direct_user, stale_user].each do |user|
      DiscourseUserCosmetics::SelectionService.select!(
        user: user,
        kind: "avatar_frame",
        item_id: item.id,
      )
    end

    group = Fabricate(:group)
    item.item_groups.create!(group: group)
    group.add(group_user)
    DiscourseUserCosmetics::UserItem.create!(user: direct_user, item: item)

    css = described_class.build_frames_css

    expect(css).to include("duc-avatar-frame-user-#{group_user.id}")
    expect(css).to include("duc-avatar-frame-user-#{direct_user.id}")
    expect(css).not_to include("duc-avatar-frame-user-#{stale_user.id}")
  end

  it "keys post avatar frames to the native transformer class without username selectors" do
    item =
      DiscourseUserCosmetics::Item.create!(
        kind: "avatar_frame",
        name: "Native post frame",
        image_url: "https://example.com/native-post-frame.webp",
      )
    user = Fabricate(:user)

    DiscourseUserCosmetics::SelectionService.select!(
      user: user,
      kind: "avatar_frame",
      item_id: item.id,
    )

    css = described_class.build_frames_css

    expect(css).to include(
      ".topic-avatar.duc-avatar-frame-user-#{user.id} .post-avatar::after",
    )
    expect(css).not_to include(%([data-user-card="#{user.username_lower}" i]:has(img.avatar)))
    expect(css).not_to include(".duc-avatar-frame-target")
    expect(css).not_to include("#user-card .user-card-avatar")
    expect(css).not_to include(".user-profile-avatar:has")
  end
end
