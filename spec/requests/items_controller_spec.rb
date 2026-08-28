# frozen_string_literal: true

RSpec.describe DiscourseUserCosmetics::ItemsController, type: :request do
  fab!(:user)

  before do
    enable_current_plugin
    sign_in(user)
  end

  it "hides disabled kinds and rejects new equips for them" do
    frame = DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: "Frame")
    plate = DiscourseUserCosmetics::Item.create!(kind: "nameplate", name: "Plate")

    SiteSetting.discourse_user_cosmetics_avatar_frames_enabled = false
    SiteSetting.discourse_user_cosmetics_nameplates_enabled = true

    get "/user-cosmetics/mine.json"

    expect(response).to be_successful
    expect(response.parsed_body.dig("items", "avatar_frame")).to eq([])
    expect(response.parsed_body.dig("active", "avatar_frame")).to be_nil
    expect(response.parsed_body.dig("items", "nameplate").map { |item| item["id"] }).to include(plate.id)

    put "/user-cosmetics/select.json", params: { kind: "avatar_frame", item_id: frame.id }

    expect(response).to have_http_status(:forbidden)
  end

  it "allows unequipping a slot after its kind has been disabled" do
    frame = DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: "Selected frame")
    DiscourseUserCosmetics::SelectionService.select!(user: user, kind: "avatar_frame", item_id: frame.id)

    SiteSetting.discourse_user_cosmetics_avatar_frames_enabled = false

    put "/user-cosmetics/select.json", params: { kind: "avatar_frame", item_id: "" }

    expect(response).to be_successful
    expect(
      DiscourseUserCosmetics::UserSelection.find_by!(user_id: user.id).avatar_frame_item_id,
    ).to be_nil
  end

  it "returns the refreshed presentation summary after equip and unequip" do
    frame =
      DiscourseUserCosmetics::Item.create!(
        kind: "avatar_frame",
        name: "Live frame",
        image_upload: Fabricate(:upload),
      )

    put "/user-cosmetics/select.json", params: { kind: "avatar_frame", item_id: frame.id }

    expect(response).to be_successful
    expect(response.parsed_body["success"]).to eq("OK")
    expect(response.parsed_body.dig("cosmetics", "avatar_frame", "id")).to eq(frame.id)

    put "/user-cosmetics/select.json", params: { kind: "avatar_frame", item_id: "" }

    expect(response).to be_successful
    expect(response.parsed_body.dig("cosmetics", "avatar_frame")).to be_nil
  end

  it "rejects an item the authenticated user cannot use" do
    restricted_group = Fabricate(:group)
    frame = DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: "Private frame")
    frame.item_groups.create!(group: restricted_group)

    put "/user-cosmetics/select.json", params: { kind: "avatar_frame", item_id: frame.id }

    expect(response).to have_http_status(:forbidden)
    expect(DiscourseUserCosmetics::UserSelection.where(user_id: user.id)).to be_empty
  end

  it "does not expose restricted group names through the user catalog" do
    restricted_group = Fabricate(:group, name: "private-cosmetic")
    frame = DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: "Private frame")
    frame.item_groups.create!(group: restricted_group)

    get "/user-cosmetics/mine.json"

    expect(response).to be_successful
    serialized =
      response.parsed_body.dig("items", "avatar_frame").find { |item| item["id"] == frame.id }
    expect(serialized).to include("owned" => false)
    expect(serialized).not_to have_key("group_names")
    expect(response.body).not_to include("private-cosmetic")
  end

  it "hides a stored active selection while its group entitlement is unavailable" do
    restricted_group = Fabricate(:group)
    restricted_group.add(user)
    frame = DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: "Temporary group frame")
    frame.item_groups.create!(group: restricted_group)

    DiscourseUserCosmetics::SelectionService.select!(
      user: user,
      kind: "avatar_frame",
      item_id: frame.id,
    )

    restricted_group.remove(user)

    get "/user-cosmetics/mine.json"

    expect(response).to be_successful
    expect(response.parsed_body.dig("active", "avatar_frame")).to be_nil
    serialized =
      response.parsed_body.dig("items", "avatar_frame").find { |item| item["id"] == frame.id }
    expect(serialized).to include("owned" => false)
    expect(
      DiscourseUserCosmetics::UserSelection.find_by!(user_id: user.id).avatar_frame_item_id,
    ).to eq(frame.id)

    restricted_group.add(user)

    get "/user-cosmetics/mine.json"

    expect(response).to be_successful
    expect(response.parsed_body.dig("active", "avatar_frame")).to eq(frame.id)
    restored =
      response.parsed_body.dig("items", "avatar_frame").find { |item| item["id"] == frame.id }
    expect(restored).to include("owned" => true)
  end

  it "keeps mine query count constant as catalog items grow while preserving entitlements" do
    member_group = Fabricate(:group)
    restricted_group = Fabricate(:group)
    member_group.add(user)

    public_item =
      DiscourseUserCosmetics::Item.create!(
        kind: "avatar_frame",
        name: "Public frame",
        image_upload: Fabricate(:upload),
      )
    group_item =
      DiscourseUserCosmetics::Item.create!(
        kind: "avatar_frame",
        name: "Group frame",
        image_upload: Fabricate(:upload),
      )
    group_item.item_groups.create!(group: member_group)
    direct_item =
      DiscourseUserCosmetics::Item.create!(
        kind: "avatar_frame",
        name: "Direct frame",
        image_upload: Fabricate(:upload),
      )
    direct_item.item_groups.create!(group: restricted_group)
    DiscourseUserCosmetics::UserItem.create!(user: user, item: direct_item)
    blocked_item =
      DiscourseUserCosmetics::Item.create!(
        kind: "avatar_frame",
        name: "Blocked frame",
        image_upload: Fabricate(:upload),
      )
    blocked_item.item_groups.create!(group: restricted_group)

    DiscourseUserCosmetics::SelectionService.select!(
      user: user,
      kind: "avatar_frame",
      item_id: group_item.id,
    )

    get "/user-cosmetics/mine.json"
    small_queries = track_sql_queries { get "/user-cosmetics/mine.json" }

    serialized = response.parsed_body.dig("items", "avatar_frame").index_by { |item| item["id"] }
    expect(serialized.fetch(public_item.id)).to include("owned" => true)
    expect(serialized.fetch(group_item.id)).to include("owned" => true)
    expect(serialized.fetch(direct_item.id)).to include("owned" => true)
    expect(serialized.fetch(blocked_item.id)).to include("owned" => false)
    expect(response.parsed_body.dig("active", "avatar_frame")).to eq(group_item.id)

    18.times do |index|
      item =
        DiscourseUserCosmetics::Item.create!(
          kind: "avatar_frame",
          name: "Scale frame #{index}",
          image_upload: Fabricate(:upload),
        )
      next if index.odd?

      item.item_groups.create!(group: restricted_group)
      DiscourseUserCosmetics::UserItem.create!(user: user, item: item) if (index % 4).zero?
    end

    large_queries = track_sql_queries { get "/user-cosmetics/mine.json" }

    expect(response).to be_successful
    expect(large_queries.size).to eq(small_queries.size)
  end
end
