# frozen_string_literal: true

RSpec.describe DiscourseUserCosmetics::CatalogItemSerializer do
  subject(:serialized) { described_class.new(item, root: false, owned: owned).as_json }

  fab!(:upload)
  fab!(:item) do
    DiscourseUserCosmetics::Item.create!(
      kind: "avatar_frame",
      name: "Catalog frame",
      description: "Visible description",
      image_upload: upload,
      gradient_from: "#112233",
      gradient_to: "#445566",
      glow_color: "#778899",
      rarity_label: "Rare",
      rarity_color: "#aabbcc",
      sort_order: 42,
    )
  end

  let(:owned) { true }

  it "serializes only the intended user catalog contract" do
    expect(serialized.keys).to contain_exactly(
      :id,
      :kind,
      :name,
      :description,
      :image_url,
      :gradient_from,
      :gradient_to,
      :glow_color,
      :rarity_label,
      :rarity_color,
      :owned,
    )
    expect(serialized).to include(
      id: item.id,
      kind: "avatar_frame",
      name: "Catalog frame",
      image_url: upload.url,
      owned: true,
    )
    expect(serialized).not_to have_key(:sort_order)
    expect(serialized).not_to have_key(:created_by_id)
    expect(serialized).not_to have_key(:group_ids)
  end

  context "when the item is not usable by the current catalog viewer" do
    let(:owned) { false }

    it "serializes the caller-provided entitlement decision as false" do
      expect(serialized[:owned]).to eq(false)
    end
  end

  context "when serializing a profile effect" do
    fab!(:item) do
      effect =
        DiscourseUserCosmetics::Item.create!(
          kind: "profile_effect",
          name: "Layered effect",
          image_url: "https://example.com/unused-effect.webp",
        )
      effect.effect_layers.create!(
        anchor: "top",
        stack_order: "front",
        image_upload: upload,
      )
      effect
    end

    it "uses the representative effect layer image for the picker preview" do
      expect(serialized[:image_url]).to eq(upload.url)
    end
  end
end
