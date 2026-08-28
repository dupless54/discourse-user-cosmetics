# frozen_string_literal: true

RSpec.describe DiscourseUserCosmetics::ShowcaseController, type: :request do
  fab!(:user)
  fab!(:other_user, :user)

  before do
    enable_current_plugin
    sign_in(user)
  end

  it "updates only the authenticated user's ordered showcase" do
    frame = DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: "Frame")
    plate = DiscourseUserCosmetics::Item.create!(kind: "nameplate", name: "Plate")

    put "/user-cosmetics/showcase.json",
        params: { item_ids: [plate.id, frame.id], user_id: other_user.id }

    expect(response).to be_successful
    expect(response.parsed_body.fetch("showcase").map { |item| item["id"] }).to eq(
      [plate.id, frame.id],
    )
    expect(
      DiscourseUserCosmetics::ShowcaseService.item_ids_for(user: user),
    ).to eq([plate.id, frame.id])
    expect(
      DiscourseUserCosmetics::ShowcaseService.item_ids_for(user: other_user),
    ).to eq([])
  end

  it "rejects an unavailable cosmetic without replacing the previous showcase" do
    frame = DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: "Frame")
    restricted = DiscourseUserCosmetics::Item.create!(kind: "nameplate", name: "Restricted")
    restricted.item_groups.create!(group: Fabricate(:group))
    DiscourseUserCosmetics::ShowcaseService.replace!(user: user, item_ids: [frame.id])

    put "/user-cosmetics/showcase.json", params: { item_ids: [restricted.id] }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(
      DiscourseUserCosmetics::ShowcaseService.item_ids_for(user: user),
    ).to eq([frame.id])
  end

  it "includes entitlement-filtered showcase data on the native public user serializer" do
    group = Fabricate(:group)
    group.add(user)
    frame =
      DiscourseUserCosmetics::Item.create!(
        kind: "avatar_frame",
        name: "Temporary showcase frame",
        image_upload: Fabricate(:upload),
      )
    frame.item_groups.create!(group: group)
    DiscourseUserCosmetics::ShowcaseService.replace!(user: user, item_ids: [frame.id])

    get "/u/#{user.username}.json"

    expect(response).to be_successful
    expect(response.parsed_body.dig("user", "cosmetics_showcase").map { |item| item["id"] }).to eq(
      [frame.id],
    )

    group.remove(user)

    get "/u/#{user.username}.json"

    expect(response).to be_successful
    expect(response.parsed_body.dig("user", "cosmetics_showcase")).to eq([])
    expect(
      DiscourseUserCosmetics::ShowcaseService.item_ids_for(user: user),
    ).to eq([frame.id])
  end
end
