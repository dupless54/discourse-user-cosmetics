# frozen_string_literal: true

RSpec.describe DiscourseUserCosmetics::ShowcaseService do
  fab!(:user)

  before { enable_current_plugin }

  it "stores an ordered showcase and exposes only presentation data" do
    frame =
      DiscourseUserCosmetics::Item.create!(
        kind: "avatar_frame",
        name: "Showcase frame",
        image_upload: Fabricate(:upload),
        rarity_label: "Rare",
      )
    plate =
      DiscourseUserCosmetics::Item.create!(
        kind: "nameplate",
        name: "Showcase plate",
        image_upload: Fabricate(:upload),
      )

    result = described_class.replace!(user: user, item_ids: [plate.id, frame.id])

    expect(described_class.item_ids_for(user: user)).to eq([plate.id, frame.id])
    expect(result.map { |item| item[:id] }).to eq([plate.id, frame.id])
    expect(result.first).to include(kind: "nameplate", name: "Showcase plate")
    expect(result.last).to include(kind: "avatar_frame", rarity_label: "Rare")
    expect(result.last).not_to have_key(:description)
  end

  it "rejects duplicates, over-limit payloads, and unavailable cosmetics without replacing the saved showcase" do
    items =
      7.times.map do |index|
        DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: "Frame #{index}")
      end
    restricted = DiscourseUserCosmetics::Item.create!(kind: "nameplate", name: "Restricted")
    restricted.item_groups.create!(group: Fabricate(:group))

    described_class.replace!(user: user, item_ids: [items.first.id])

    expect do
      described_class.replace!(user: user, item_ids: [items.first.id, items.first.id])
    end.to raise_error(described_class::InvalidShowcase)

    expect do
      described_class.replace!(user: user, item_ids: items.map(&:id))
    end.to raise_error(described_class::InvalidShowcase)

    expect do
      described_class.replace!(user: user, item_ids: [restricted.id])
    end.to raise_error(described_class::InvalidShowcase)

    expect(described_class.item_ids_for(user: user)).to eq([items.first.id])
  end

  it "filters saved items from public output when entitlement is later lost" do
    group = Fabricate(:group)
    group.add(user)
    frame = DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: "Group frame")
    frame.item_groups.create!(group: group)

    described_class.replace!(user: user, item_ids: [frame.id])
    expect(described_class.serialize_for(user: user).map { |item| item[:id] }).to eq([frame.id])

    group.remove(user)

    expect(described_class.item_ids_for(user: user)).to eq([frame.id])
    expect(described_class.serialize_for(user: user)).to eq([])
  end

  it "exposes the showcase through the public Integration contract" do
    frame = DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: "Integration frame")

    expect(DiscourseUserCosmetics::Integration.showcase_supported?).to eq(true)
    result =
      DiscourseUserCosmetics::Integration.update_showcase!(
        user: user,
        item_ids: [frame.id],
      )

    expect(result.map { |item| item[:id] }).to eq([frame.id])
    expect(
      DiscourseUserCosmetics::Integration.showcase_for(user: user).map { |item| item[:id] },
    ).to eq([frame.id])
  end
end
