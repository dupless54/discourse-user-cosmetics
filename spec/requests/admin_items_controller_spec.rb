# frozen_string_literal: true

RSpec.describe DiscourseUserCosmetics::AdminItemsController, type: :request do
  fab!(:admin)
  fab!(:moderator)

  before { enable_current_plugin }

  it "persists profile-effect side offsets and permitted nested layers" do
    sign_in(admin)

    post "/admin/plugins/user-cosmetics/items.json",
         params: {
           item: {
             kind: "profile_effect",
             name: "Side clipped effect",
             effect_side_offset_top: 120,
             effect_side_offset_bottom: 80,
             layers: [
               {
                 anchor: "left",
                 stack_order: "front",
                 image_url: "https://example.com/left.webp",
                 ignored_admin_field: "must-not-be-consumed",
               },
             ],
           },
         }

    expect(response).to be_successful

    item = DiscourseUserCosmetics::Item.find(response.parsed_body["id"])
    expect(item.effect_side_offset_top).to eq(120)
    expect(item.effect_side_offset_bottom).to eq(80)
    expect(item.effect_layers.pluck(:anchor, :stack_order, :image_url)).to eq(
      [["left", "front", "https://example.com/left.webp"]],
    )
    expect(response.parsed_body).to include(
      "effect_side_offset_top" => 120,
      "effect_side_offset_bottom" => 80,
    )
  end

  it "rolls back item, group, and layer changes when a nested layer is invalid" do
    sign_in(admin)

    original_group = Fabricate(:group)
    replacement_group = Fabricate(:group)
    item =
      DiscourseUserCosmetics::Item.create!(
        kind: "profile_effect",
        name: "Original effect",
        effect_side_offset_top: 10,
      )
    item.item_groups.create!(group: original_group)
    item.effect_layers.create!(
      anchor: "top",
      stack_order: "front",
      image_url: "https://example.com/original.webp",
    )

    put "/admin/plugins/user-cosmetics/items/#{item.id}.json",
        params: {
          item: {
            name: "Partially changed effect",
            effect_side_offset_top: 500,
            group_ids: [replacement_group.id],
            layers: [
              {
                anchor: "full",
                stack_order: "front",
                image_url: "https://example.com/first.webp",
              },
              {
                anchor: "full",
                stack_order: "front",
                image_url: "https://example.com/duplicate.webp",
              },
            ],
          },
        }

    expect(response.status).to be >= 400

    item.reload
    expect(item.name).to eq("Original effect")
    expect(item.effect_side_offset_top).to eq(10)
    expect(item.groups.pluck(:id)).to eq([original_group.id])
    expect(item.effect_layers.pluck(:anchor, :stack_order, :image_url)).to eq(
      [["top", "front", "https://example.com/original.webp"]],
    )
  end

  it "does not allow moderators to manage the cosmetic catalog" do
    sign_in(moderator)

    post "/admin/plugins/user-cosmetics/items.json",
         params: {
           item: {
             kind: "avatar_frame",
             name: "Forbidden frame",
           },
         }

    expect(response).to have_http_status(:forbidden)
    expect(DiscourseUserCosmetics::Item.where(name: "Forbidden frame")).to be_empty
  end
end
