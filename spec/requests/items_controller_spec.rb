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

  it "rejects an item the authenticated user cannot use" do
    restricted_group = Fabricate(:group)
    frame = DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: "Private frame")
    frame.item_groups.create!(group: restricted_group)

    put "/user-cosmetics/select.json", params: { kind: "avatar_frame", item_id: frame.id }

    expect(response).to have_http_status(:forbidden)
    expect(DiscourseUserCosmetics::UserSelection.where(user_id: user.id)).to be_empty
  end

  it "does not expose restricted group names through the user catalog" do
    restricted_group = Fabricate(:group, name: "private-cosmetics-group")
    frame = DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: "Private frame")
    frame.item_groups.create!(group: restricted_group)

    get "/user-cosmetics/mine.json"

    expect(response).to be_successful
    serialized =
      response.parsed_body.dig("items", "avatar_frame").find { |item| item["id"] == frame.id }
    expect(serialized).to include("owned" => false)
    expect(serialized).not_to have_key("group_names")
    expect(response.body).not_to include("private-cosmetics-group")
  end
end
