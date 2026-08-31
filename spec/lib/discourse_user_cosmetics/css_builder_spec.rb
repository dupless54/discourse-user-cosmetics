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

  it "keeps the native post frame and centers ambient DUserLink avatar frames on avatar geometry" do
    SiteSetting.discourse_user_cosmetics_frame_overhang_percent = 14
    item =
      DiscourseUserCosmetics::Item.create!(
        kind: "avatar_frame",
        name: "Native and ambient frame",
        image_url: "https://example.com/native-post-frame.webp",
      )
    user = Fabricate(:user)

    DiscourseUserCosmetics::SelectionService.select!(
      user: user,
      kind: "avatar_frame",
      item_id: item.id,
    )

    css = described_class.build_frames_css
    ambient_selector =
      %([data-user-card="#{user.username_lower}" i]:has(img.avatar):not(.main-avatar))

    expect(css).to include(
      ".topic-avatar.duc-avatar-frame-user-#{user.id} .post-avatar::after",
    )
    expect(css).to include("inset: -14%;")
    expect(css).to include("#{ambient_selector}::after")
    expect(css).to include("top: 0;")
    expect(css).to include("left: 0;")
    expect(css).to include("width: 100%;")
    expect(css).to include("aspect-ratio: 1;")
    expect(css).to include("transform: scale(1.28);")
    expect(css).to include("transform-origin: center;")
    expect(css).not_to include(".duc-avatar-frame-target")
    expect(css).not_to include("#user-card .user-card-avatar")
    expect(css).not_to include(".user-profile-avatar:has")
  end

  it "keeps native post and mention nameplates and restores ambient DUserLink names" do
    item =
      DiscourseUserCosmetics::Item.create!(
        kind: "nameplate",
        name: "Native and ambient nameplate",
        image_url: "https://example.com/native-nameplate.webp",
      )
    user = Fabricate(:user)

    DiscourseUserCosmetics::SelectionService.select!(
      user: user,
      kind: "nameplate",
      item_id: item.id,
    )

    css = described_class.build_frames_css

    expect(css).to include(".duc-nameplate-post-user-#{user.id}")
    expect(css).to include(".duc-nameplate-post-user-#{user.id} > a")
    expect(css).to include("a.mention.duc-nameplate-mention-user-#{user.id}")
    expect(css).to include(
      %([data-user-card="#{user.username_lower}" i]:not(:has(img.avatar)):not(.mention):not(.duc-nameplate-post-user-#{user.id} *)),
    )
    expect(css).not_to include(%(href^="/u/#{user.username_lower}"))
  end
end
