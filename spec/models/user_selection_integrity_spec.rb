# frozen_string_literal: true

RSpec.describe "DiscourseUserCosmetics selection integrity" do
  fab!(:user)

  before { enable_current_plugin }

  it "rejects direct writes that put an unusable item in an active slot" do
    restricted_group = Fabricate(:group)
    item = DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: "Restricted frame")
    item.item_groups.create!(group: restricted_group)

    selection =
      DiscourseUserCosmetics::UserSelection.new(
        user: user,
        avatar_frame_item_id: item.id,
      )

    expect(selection).not_to be_valid
    expect(selection.errors[:avatar_frame_item_id]).to be_present
  end

  it "clears an active selection when direct ownership is revoked and no entitlement remains" do
    restricted_group = Fabricate(:group)
    item = DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: "Granted frame")
    item.item_groups.create!(group: restricted_group)
    ownership = DiscourseUserCosmetics::UserItem.create!(user: user, item: item)

    DiscourseUserCosmetics::SelectionService.select!(
      user: user,
      kind: "avatar_frame",
      item_id: item.id,
    )

    ownership.destroy!

    selection = DiscourseUserCosmetics::UserSelection.find_by!(user_id: user.id)
    expect(selection.avatar_frame_item_id).to be_nil
  end

  it "keeps the active selection when a revoked direct grant is not the user's final entitlement" do
    item = DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: "Public frame")
    ownership = DiscourseUserCosmetics::UserItem.create!(user: user, item: item)

    DiscourseUserCosmetics::SelectionService.select!(
      user: user,
      kind: "avatar_frame",
      item_id: item.id,
    )

    ownership.destroy!

    selection = DiscourseUserCosmetics::UserSelection.find_by!(user_id: user.id)
    expect(selection.avatar_frame_item_id).to eq(item.id)
  end

  it "clears active selections automatically when a catalog item is disabled" do
    item = DiscourseUserCosmetics::Item.create!(kind: "nameplate", name: "Temporary plate")

    DiscourseUserCosmetics::SelectionService.select!(
      user: user,
      kind: "nameplate",
      item_id: item.id,
    )

    item.update!(enabled: false)

    selection = DiscourseUserCosmetics::UserSelection.find_by!(user_id: user.id)
    expect(selection.nameplate_item_id).to be_nil
  end

  it "clears a public selection when a new group restriction removes access" do
    item = DiscourseUserCosmetics::Item.create!(kind: "card_decoration", name: "Public card")
    restricted_group = Fabricate(:group)

    DiscourseUserCosmetics::SelectionService.select!(
      user: user,
      kind: "card_decoration",
      item_id: item.id,
    )

    item.item_groups.create!(group: restricted_group)

    selection = DiscourseUserCosmetics::UserSelection.find_by!(user_id: user.id)
    expect(selection.card_decoration_item_id).to be_nil
  end

  it "clears active selections when an item is destroyed directly" do
    item = DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: "Deleted frame")

    DiscourseUserCosmetics::SelectionService.select!(
      user: user,
      kind: "avatar_frame",
      item_id: item.id,
    )

    item.destroy!

    selection = DiscourseUserCosmetics::UserSelection.find_by!(user_id: user.id)
    expect(selection.avatar_frame_item_id).to be_nil
  end

  it "does not allow a persisted catalog item to change kind" do
    item = DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: "Stable kind")

    item.kind = "nameplate"

    expect(item).not_to be_valid
    expect(item.errors[:kind]).to be_present
  end
end
