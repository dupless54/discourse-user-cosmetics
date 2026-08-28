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

    expect(response).to have_http_status(:unprocessable_entity)

    item.reload
    expect(item.name).to eq("Original effect")
    expect(item.effect_side_offset_top).to eq(10)
    expect(item.groups.pluck(:id)).to eq([original_group.id])
    expect(item.effect_layers.pluck(:anchor, :stack_order, :image_url)).to eq(
      [["top", "front", "https://example.com/original.webp"]],
    )
  end

  it "rejects an invalid layer coordinate instead of silently dropping it" do
    sign_in(admin)

    original_group = Fabricate(:group)
    replacement_group = Fabricate(:group)
    item = DiscourseUserCosmetics::Item.create!(kind: "profile_effect", name: "Original effect")
    item.item_groups.create!(group: original_group)
    item.effect_layers.create!(
      anchor: "top",
      stack_order: "front",
      image_url: "https://example.com/original.webp",
    )

    put "/admin/plugins/user-cosmetics/items/#{item.id}.json",
        params: {
          item: {
            name: "Should roll back",
            group_ids: [replacement_group.id],
            layers: [
              {
                anchor: "diagonal",
                stack_order: "front",
                image_url: "https://example.com/invalid.webp",
              },
            ],
          },
        }

    expect(response).to have_http_status(:unprocessable_entity)

    item.reload
    expect(item.name).to eq("Original effect")
    expect(item.groups.pluck(:id)).to eq([original_group.id])
    expect(item.effect_layers.pluck(:anchor, :stack_order, :image_url)).to eq(
      [["top", "front", "https://example.com/original.webp"]],
    )
  end

  it "rejects an assetless layer and rolls back new item creation" do
    sign_in(admin)

    post "/admin/plugins/user-cosmetics/items.json",
         params: {
           item: {
             kind: "profile_effect",
             name: "Incomplete effect",
             layers: [
               {
                 anchor: "top",
                 stack_order: "front",
               },
             ],
           },
         }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(DiscourseUserCosmetics::Item.where(name: "Incomplete effect")).to be_empty
  end

  it "preserves groups and profile-effect layers when a partial update omits them" do
    sign_in(admin)

    restricted_group = Fabricate(:group)
    item = DiscourseUserCosmetics::Item.create!(kind: "profile_effect", name: "Original effect")
    item.item_groups.create!(group: restricted_group)
    item.effect_layers.create!(
      anchor: "left",
      stack_order: "front",
      image_url: "https://example.com/original.webp",
    )

    put "/admin/plugins/user-cosmetics/items/#{item.id}.json",
        params: { item: { name: "Renamed effect" } }

    expect(response).to be_successful
    item.reload
    expect(item.name).to eq("Renamed effect")
    expect(item.groups.pluck(:id)).to eq([restricted_group.id])
    expect(item.effect_layers.pluck(:anchor, :stack_order, :image_url)).to eq(
      [["left", "front", "https://example.com/original.webp"]],
    )
  end

  it "clears a selection after the final admin group set removes access" do
    sign_in(admin)

    user = Fabricate(:user)
    restricted_group = Fabricate(:group)
    item = DiscourseUserCosmetics::Item.create!(kind: "card_decoration", name: "Public card")
    DiscourseUserCosmetics::SelectionService.select!(
      user: user,
      kind: "card_decoration",
      item_id: item.id,
    )

    put "/admin/plugins/user-cosmetics/items/#{item.id}.json",
        params: { item: { group_ids: [restricted_group.id] } }

    expect(response).to be_successful
    expect(
      DiscourseUserCosmetics::UserSelection.find_by!(user_id: user.id).card_decoration_item_id,
    ).to be_nil
  end

  it "keeps a selection when the completed admin group set still grants access" do
    sign_in(admin)

    user = Fabricate(:user)
    denied_group = Fabricate(:group)
    allowed_group = Fabricate(:group)
    allowed_group.add(user)
    item = DiscourseUserCosmetics::Item.create!(kind: "card_decoration", name: "Public card")
    DiscourseUserCosmetics::SelectionService.select!(
      user: user,
      kind: "card_decoration",
      item_id: item.id,
    )

    # The denied group is intentionally first. Cleanup must run only after the
    # complete replacement set exists, otherwise this valid selection can be
    # cleared while the allowed group has not been inserted yet.
    put "/admin/plugins/user-cosmetics/items/#{item.id}.json",
        params: { item: { group_ids: [denied_group.id, allowed_group.id] } }

    expect(response).to be_successful
    expect(
      DiscourseUserCosmetics::UserSelection.find_by!(user_id: user.id).card_decoration_item_id,
    ).to eq(item.id)
  end

  it "reactivates a stale selected card with only targeted user-cache invalidation" do
    sign_in(admin)

    user = Fabricate(:user)
    item = DiscourseUserCosmetics::Item.create!(kind: "card_decoration", name: "Grant card")
    DiscourseUserCosmetics::SelectionService.select!(
      user: user,
      kind: "card_decoration",
      item_id: item.id,
    )
    item.item_groups.create!(group: Fabricate(:group))

    expect(DiscourseUserCosmetics::Presenter.summary_for(user)["card_decoration"]).to be_nil

    global_version = DiscourseUserCosmetics::Presenter.cache_version
    user_version = DiscourseUserCosmetics::Presenter.user_cache_version(user.id)
    stylesheet_version = DiscourseUserCosmetics::Presenter.stylesheet_version

    post "/admin/plugins/user-cosmetics/items/#{item.id}/grant.json",
         params: { username: user.username }

    expect(response).to be_successful
    expect(DiscourseUserCosmetics::Presenter.cache_version).to eq(global_version)
    expect(DiscourseUserCosmetics::Presenter.user_cache_version(user.id)).not_to eq(user_version)
    expect(DiscourseUserCosmetics::Presenter.stylesheet_version).to eq(stylesheet_version)
    expect(DiscourseUserCosmetics::Presenter.summary_for(user)["card_decoration"]).to include(id: item.id)
    expect(
      DiscourseUserCosmetics::UserItem.find_by!(user_id: user.id, item_id: item.id).granted_by_id,
    ).to eq(admin.id)
  end

  it "reactivates stale frame CSS without globally invalidating presentation caches" do
    sign_in(admin)

    user = Fabricate(:user)
    item =
      DiscourseUserCosmetics::Item.create!(
        kind: "avatar_frame",
        name: "Grant frame",
        image_url: "https://example.com/grant-frame.webp",
      )
    DiscourseUserCosmetics::SelectionService.select!(
      user: user,
      kind: "avatar_frame",
      item_id: item.id,
    )
    item.item_groups.create!(group: Fabricate(:group))

    expect(DiscourseUserCosmetics::Presenter.summary_for(user)["avatar_frame"]).to be_nil

    global_version = DiscourseUserCosmetics::Presenter.cache_version
    user_version = DiscourseUserCosmetics::Presenter.user_cache_version(user.id)
    stylesheet_version = DiscourseUserCosmetics::Presenter.stylesheet_version

    post "/admin/plugins/user-cosmetics/items/#{item.id}/grant.json",
         params: { username: user.username }

    expect(response).to be_successful
    expect(DiscourseUserCosmetics::Presenter.cache_version).to eq(global_version)
    expect(DiscourseUserCosmetics::Presenter.user_cache_version(user.id)).not_to eq(user_version)
    expect(DiscourseUserCosmetics::Presenter.stylesheet_version).not_to eq(stylesheet_version)
    expect(DiscourseUserCosmetics::Presenter.summary_for(user)["avatar_frame"]).to include(id: item.id)
  end

  it "does not invalidate presentation caches when granting an unselected restricted item" do
    sign_in(admin)

    user = Fabricate(:user)
    item = DiscourseUserCosmetics::Item.create!(kind: "profile_effect", name: "Unselected effect")
    item.item_groups.create!(group: Fabricate(:group))

    global_version = DiscourseUserCosmetics::Presenter.cache_version
    user_version = DiscourseUserCosmetics::Presenter.user_cache_version(user.id)
    stylesheet_version = DiscourseUserCosmetics::Presenter.stylesheet_version

    post "/admin/plugins/user-cosmetics/items/#{item.id}/grant.json",
         params: { username: user.username }

    expect(response).to be_successful
    expect(DiscourseUserCosmetics::Presenter.cache_version).to eq(global_version)
    expect(DiscourseUserCosmetics::Presenter.user_cache_version(user.id)).to eq(user_version)
    expect(DiscourseUserCosmetics::Presenter.stylesheet_version).to eq(stylesheet_version)
  end

  it "does not invalidate caches when a direct grant adds no new effective access" do
    sign_in(admin)

    user = Fabricate(:user)
    item =
      DiscourseUserCosmetics::Item.create!(
        kind: "avatar_frame",
        name: "Already public frame",
        image_url: "https://example.com/public-frame.webp",
      )
    DiscourseUserCosmetics::SelectionService.select!(
      user: user,
      kind: "avatar_frame",
      item_id: item.id,
    )

    global_version = DiscourseUserCosmetics::Presenter.cache_version
    user_version = DiscourseUserCosmetics::Presenter.user_cache_version(user.id)
    stylesheet_version = DiscourseUserCosmetics::Presenter.stylesheet_version

    post "/admin/plugins/user-cosmetics/items/#{item.id}/grant.json",
         params: { username: user.username }

    expect(response).to be_successful
    expect(DiscourseUserCosmetics::Presenter.cache_version).to eq(global_version)
    expect(DiscourseUserCosmetics::Presenter.user_cache_version(user.id)).to eq(user_version)
    expect(DiscourseUserCosmetics::Presenter.stylesheet_version).to eq(stylesheet_version)
  end

  it "does not invalidate caches for a duplicate direct grant" do
    sign_in(admin)

    user = Fabricate(:user)
    item = DiscourseUserCosmetics::Item.create!(kind: "card_decoration", name: "Duplicate grant card")
    item.item_groups.create!(group: Fabricate(:group))
    DiscourseUserCosmetics::UserItem.create!(user: user, item: item, granted_by: admin)

    global_version = DiscourseUserCosmetics::Presenter.cache_version
    user_version = DiscourseUserCosmetics::Presenter.user_cache_version(user.id)
    stylesheet_version = DiscourseUserCosmetics::Presenter.stylesheet_version

    post "/admin/plugins/user-cosmetics/items/#{item.id}/grant.json",
         params: { username: user.username }

    expect(response).to be_successful
    expect(DiscourseUserCosmetics::UserItem.where(user_id: user.id, item_id: item.id).count).to eq(1)
    expect(DiscourseUserCosmetics::Presenter.cache_version).to eq(global_version)
    expect(DiscourseUserCosmetics::Presenter.user_cache_version(user.id)).to eq(user_version)
    expect(DiscourseUserCosmetics::Presenter.stylesheet_version).to eq(stylesheet_version)
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
