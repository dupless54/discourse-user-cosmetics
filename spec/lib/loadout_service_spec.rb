# frozen_string_literal: true

RSpec.describe DiscourseUserCosmetics::LoadoutService do
  fab!(:user)
  fab!(:other_user, :user)

  before { enable_current_plugin }

  it "captures the current four-slot selection and restores it atomically" do
    saved_items = create_items("Saved")
    replacement_items = create_items("Replacement")

    equip_items(user, saved_items)
    loadout = described_class.create_from_current!(user: user, name: "  Gece Seti  ")

    expect(loadout.name).to eq("Gece Seti")
    expect(loadout.selection_item_ids).to eq(saved_items.transform_values(&:id))

    equip_items(user, replacement_items)
    described_class.apply!(user: user, loadout_id: loadout.id)

    expect(current_selection(user)).to eq(saved_items.transform_values(&:id))
  end

  it "leaves every current slot unchanged when one saved item is no longer entitled" do
    saved_items = create_items("Saved")
    restricted = saved_items.fetch("avatar_frame")
    restricted.item_groups.create!(group: Fabricate(:group))
    DiscourseUserCosmetics::Integration.grant!(user: user, item: restricted)

    equip_items(user, saved_items)
    loadout = described_class.create_from_current!(user: user, name: "Korumalı Set")

    DiscourseUserCosmetics::Integration.revoke!(user: user, item: restricted)
    replacement_items = create_items("Current")
    equip_items(user, replacement_items)
    before_apply = current_selection(user)

    expect do
      described_class.apply!(user: user, loadout_id: loadout.id)
    end.to raise_error(Discourse::InvalidAccess)

    expect(current_selection(user)).to eq(before_apply)
  end

  it "scopes rename, delete, and apply to the authenticated user" do
    loadout = described_class.create_from_current!(user: other_user, name: "Başkasının Seti")

    expect do
      described_class.rename!(user: user, loadout_id: loadout.id, name: "Çalınan")
    end.to raise_error(Discourse::NotFound)
    expect do
      described_class.destroy!(user: user, loadout_id: loadout.id)
    end.to raise_error(Discourse::NotFound)
    expect do
      described_class.apply!(user: user, loadout_id: loadout.id)
    end.to raise_error(Discourse::NotFound)

    expect(loadout.reload.name).to eq("Başkasının Seti")
  end

  it "enforces the per-user loadout limit" do
    described_class::MAX_LOADOUTS_PER_USER.times do |index|
      described_class.create_from_current!(user: user, name: "Set #{index + 1}")
    end

    expect do
      described_class.create_from_current!(user: user, name: "Fazla Set")
    end.to raise_error(Discourse::InvalidParameters)
  end

  it "clears a deleted catalog item from saved loadout slots" do
    item = create_item("avatar_frame", "Silinecek Çerçeve")
    DiscourseUserCosmetics::SelectionService.select!(
      user: user,
      kind: item.kind,
      item_id: item.id,
    )
    loadout = described_class.create_from_current!(user: user, name: "Eski Set")

    item.destroy!

    expect(loadout.reload.avatar_frame_item_id).to be_nil
  end

  it "removes saved loadouts when the owning user is destroyed" do
    loadout = described_class.create_from_current!(user: user, name: "Geçici Set")
    loadout_id = loadout.id

    user.destroy!

    expect(DiscourseUserCosmetics::Loadout.where(id: loadout_id)).to be_empty
  end

  def create_items(prefix)
    DiscourseUserCosmetics::Item::KINDS.index_with do |kind|
      create_item(kind, "#{prefix} #{kind}")
    end
  end

  def create_item(kind, name)
    DiscourseUserCosmetics::Item.create!(kind: kind, name: name, enabled: true)
  end

  def equip_items(candidate, items)
    items.each_value do |item|
      DiscourseUserCosmetics::SelectionService.select!(
        user: candidate,
        kind: item.kind,
        item_id: item.id,
      )
    end
  end

  def current_selection(candidate)
    selection = DiscourseUserCosmetics::UserSelection.find_by!(user_id: candidate.id)
    DiscourseUserCosmetics::Item::KINDS.index_with do |kind|
      selection.public_send(DiscourseUserCosmetics::UserSelection.field_for(kind))
    end
  end
end
