# frozen_string_literal: true

RSpec.describe DiscourseUserCosmetics::AdminItemsController, type: :request do
  fab!(:admin)

  before do
    enable_current_plugin
    sign_in(admin)
  end

  it "keeps admin catalog query count constant as items, groups, and owners grow" do
    group = Fabricate(:group)
    owner = Fabricate(:user)
    base_item =
      DiscourseUserCosmetics::Item.create!(
        kind: "profile_effect",
        name: "Measured admin effect",
        image_upload: Fabricate(:upload),
      )
    base_item.item_groups.create!(group: group)
    base_item.effect_layers.create!(
      anchor: "top",
      stack_order: "front",
      image_upload: Fabricate(:upload),
    )
    DiscourseUserCosmetics::UserItem.create!(user: owner, item: base_item)

    get "/admin/plugins/user-cosmetics/items.json"
    small_queries = track_sql_queries { get "/admin/plugins/user-cosmetics/items.json" }

    serialized = response.parsed_body.fetch("items").find { |item| item["id"] == base_item.id }
    expect(serialized).to include(
      "group_ids" => [group.id],
      "group_names" => [group.name],
      "owner_count" => 1,
    )
    expect(serialized.fetch("layers").size).to eq(1)

    12.times do |index|
      item =
        DiscourseUserCosmetics::Item.create!(
          kind: "avatar_frame",
          name: "Measured admin frame #{index}",
          image_upload: Fabricate(:upload),
        )
      item.item_groups.create!(group: group)
      DiscourseUserCosmetics::UserItem.create!(user: Fabricate(:user), item: item)
    end

    large_queries = track_sql_queries { get "/admin/plugins/user-cosmetics/items.json" }

    expect(response).to be_successful
    expect(large_queries.size).to eq(small_queries.size)
  end
end
