# frozen_string_literal: true

RSpec.describe DiscourseUserCosmetics::Integration do
  fab!(:user)

  before { enable_current_plugin }

  after { described_class.unregister_entitlement_provider("loadout-provider-allow") }

  it "keeps model selection validation aligned with provider-granted entitlement" do
    item = DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: "Provider Frame")
    item.item_groups.create!(group: Fabricate(:group))

    described_class.register_entitlement_provider("loadout-provider-allow") do |user:, items:, **_kwargs|
      expect(user).to eq(self.user)
      items.index_with(true).transform_keys(&:id)
    end

    described_class.equip!(user: user, item: item)

    selection = DiscourseUserCosmetics::UserSelection.find_by!(user_id: user.id)
    expect(selection.avatar_frame_item_id).to eq(item.id)
  end

  it "exposes safe loadout payloads and supports create, rename, apply, and delete" do
    frame = DiscourseUserCosmetics::Item.create!(
      kind: "avatar_frame",
      name: "Night Frame",
      rarity_label: "Epic",
      rarity_color: "#663399",
    )
    effect = DiscourseUserCosmetics::Item.create!(kind: "profile_effect", name: "Night Effect")
    described_class.equip!(user: user, item: frame)
    described_class.equip!(user: user, item: effect)

    created = described_class.create_loadout!(user: user, name: "Night")

    expect(created[:name]).to eq("Night")
    expect(created[:can_apply]).to eq(true)
    expect(created[:slots]["avatar_frame"][:item]).to include(
      id: frame.id,
      kind: "avatar_frame",
      name: "Night Frame",
      rarity_label: "Epic",
      rarity_color: "#663399",
    )
    expect(created[:slots]["nameplate"]).to eq(item_id: nil, available: true, item: nil)

    renamed = described_class.rename_loadout!(
      user: user,
      loadout_id: created[:id],
      name: "Night V2",
    )
    expect(renamed[:name]).to eq("Night V2")

    described_class.unequip!(user: user, kind: "avatar_frame")
    applied = described_class.apply_loadout!(user: user, loadout_id: created[:id])
    expect(applied[:loadout][:can_apply]).to eq(true)
    expect(applied[:cosmetics]["avatar_frame"] || applied[:cosmetics][:avatar_frame]).to include(id: frame.id)

    expect(described_class.delete_loadout!(user: user, loadout_id: created[:id])).to eq(true)
    expect(described_class.loadouts_for(user: user)).to be_empty
  end

  it "marks a saved loadout unavailable when its entitlement is lost" do
    item = DiscourseUserCosmetics::Item.create!(kind: "nameplate", name: "Exclusive Plate")
    item.item_groups.create!(group: Fabricate(:group))
    described_class.grant!(user: user, item: item)
    described_class.equip!(user: user, item: item)
    created = described_class.create_loadout!(user: user, name: "Exclusive")

    described_class.revoke!(user: user, item: item)
    payload = described_class.loadouts_for(user: user).find { |row| row[:id] == created[:id] }

    expect(payload[:can_apply]).to eq(false)
    expect(payload[:slots]["nameplate"][:available]).to eq(false)
    expect do
      described_class.apply_loadout!(user: user, loadout_id: created[:id])
    end.to raise_error(Discourse::InvalidAccess)
  end
end
