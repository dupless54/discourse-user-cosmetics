# frozen_string_literal: true

RSpec.describe DiscourseUserCosmetics::Integration do
  fab!(:user)
  fab!(:admin)

  before { enable_current_plugin }

  after do
    %w[test-deny test-allow ownership-gate invalid].each do |name|
      described_class.unregister_entitlement_provider(name)
    end
  end

  it "applies batch entitlement providers once and lets denial win" do
    public_item = DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: "Public frame")
    restricted_item = DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: "Restricted frame")
    restricted_item.item_groups.create!(group: Fabricate(:group))
    deny_calls = 0
    allow_calls = 0

    described_class.register_entitlement_provider("test-deny") do |user:, items:, usable_item_ids:|
      expect(user).to eq(self.user)
      expect(items.map(&:id)).to match_array([public_item.id, restricted_item.id])
      expect(usable_item_ids).to include(public_item.id => true)
      deny_calls += 1
      { public_item.id => false }
    end
    described_class.register_entitlement_provider("test-allow") do |**_kwargs|
      allow_calls += 1
      { public_item.id => true, restricted_item.id => true }
    end

    usable =
      DiscourseUserCosmetics::EntitlementResolver.usable_item_ids(
        user: user,
        items: [public_item, restricted_item],
      )

    expect(deny_calls).to eq(1)
    expect(allow_calls).to eq(1)
    expect(usable).not_to have_key(public_item.id)
    expect(usable).to include(restricted_item.id => true)
  end

  it "keeps direct ownership distinct from entitlement and grants idempotently" do
    item = DiscourseUserCosmetics::Item.create!(kind: "nameplate", name: "Restricted plate")
    item.item_groups.create!(group: Fabricate(:group))

    expect(described_class.owns?(user: user, item: item)).to eq(false)
    expect(described_class.entitled?(user: user, item: item)).to eq(false)

    first = described_class.grant!(user: user, item: item, granted_by: admin)
    second = described_class.grant!(user: user, item: item, granted_by: admin)

    expect(first.id).to eq(second.id)
    expect(first.granted_by_id).to eq(admin.id)
    expect(DiscourseUserCosmetics::UserItem.where(user: user, item: item).count).to eq(1)
    expect(described_class.owns?(user: user, item: item)).to eq(true)
    expect(described_class.entitled?(user: user, item: item)).to eq(true)
  end

  it "clears an active selection when a provider denies access after direct ownership is revoked" do
    item = DiscourseUserCosmetics::Item.create!(kind: "card_decoration", name: "Exclusive card")

    described_class.register_entitlement_provider("ownership-gate") do |user:, items:, **_kwargs|
      owned_ids =
        DiscourseUserCosmetics::UserItem.where(
          user_id: user.id,
          item_id: items.map(&:id),
        ).pluck(:item_id).to_set
      items.index_with { |candidate| owned_ids.include?(candidate.id) }.transform_keys(&:id)
    end

    described_class.grant!(user: user, item: item)
    described_class.equip!(user: user, item: item)
    expect(user_selection.card_decoration_item_id).to eq(item.id)

    expect(described_class.revoke!(user: user, item: item)).to eq(1)
    expect(user_selection.reload.card_decoration_item_id).to be_nil
    expect(described_class.entitled?(user: user, item: item)).to eq(false)
  end

  it "equips and unequips through the server-authoritative selection service" do
    item = DiscourseUserCosmetics::Item.create!(kind: "profile_effect", name: "Owned effect")
    item.item_groups.create!(group: Fabricate(:group))
    described_class.grant!(user: user, item: item)

    described_class.equip!(user: user, item: item)
    expect(user_selection.profile_effect_item_id).to eq(item.id)

    described_class.unequip!(user: user, kind: "profile_effect")
    expect(user_selection.reload.profile_effect_item_id).to be_nil
  end

  it "returns all current selection ids through the public contract" do
    frame = DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: "Frame")
    plate = DiscourseUserCosmetics::Item.create!(kind: "nameplate", name: "Plate")

    described_class.equip!(user: user, item: frame)
    described_class.equip!(user: user, item: plate)

    expect(described_class.current_selections_for(user: user)).to eq(
      "avatar_frame" => frame.id,
      "nameplate" => plate.id,
      "card_decoration" => nil,
      "profile_effect" => nil,
    )
  end

  it "applies a complete preview selection atomically and returns server truth" do
    frame = DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: "Frame")
    plate = DiscourseUserCosmetics::Item.create!(kind: "nameplate", name: "Plate")
    card = DiscourseUserCosmetics::Item.create!(kind: "card_decoration", name: "Card")
    effect = DiscourseUserCosmetics::Item.create!(kind: "profile_effect", name: "Effect")

    result =
      described_class.apply_selections!(
        user: user,
        selections: {
          avatar_frame: frame.id,
          nameplate: plate.id,
          card_decoration: card.id,
          profile_effect: effect.id,
        },
      )

    expect(result[:selections]).to eq(
      "avatar_frame" => frame.id,
      "nameplate" => plate.id,
      "card_decoration" => card.id,
      "profile_effect" => effect.id,
    )
    expect(result[:cosmetics].dig(:avatar_frame, :id)).to eq(frame.id)
    expect(result[:cosmetics].dig(:nameplate, :id)).to eq(plate.id)
    expect(result[:cosmetics].dig(:card_decoration, :id)).to eq(card.id)
    expect(result[:cosmetics].dig(:profile_effect, :id)).to eq(effect.id)
  end

  it "does not partially apply preview selections when one item is unavailable" do
    old_frame = DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: "Old frame")
    old_plate = DiscourseUserCosmetics::Item.create!(kind: "nameplate", name: "Old plate")
    new_frame = DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: "New frame")
    restricted_plate = DiscourseUserCosmetics::Item.create!(kind: "nameplate", name: "Restricted plate")
    restricted_plate.item_groups.create!(group: Fabricate(:group))

    described_class.apply_selections!(
      user: user,
      selections: {
        avatar_frame: old_frame.id,
        nameplate: old_plate.id,
        card_decoration: nil,
        profile_effect: nil,
      },
    )

    expect do
      described_class.apply_selections!(
        user: user,
        selections: {
          avatar_frame: new_frame.id,
          nameplate: restricted_plate.id,
          card_decoration: nil,
          profile_effect: nil,
        },
      )
    end.to raise_error(Discourse::InvalidAccess)

    expect(described_class.current_selections_for(user: user)).to eq(
      "avatar_frame" => old_frame.id,
      "nameplate" => old_plate.id,
      "card_decoration" => nil,
      "profile_effect" => nil,
    )
  end

  it "rejects invalid provider output instead of silently broadening access" do
    item = DiscourseUserCosmetics::Item.create!(kind: "avatar_frame", name: "Frame")
    described_class.register_entitlement_provider("invalid") { |**_kwargs| { item.id => :allow } }

    expect do
      DiscourseUserCosmetics::EntitlementResolver.usable_item_ids(user: user, items: [item])
    end.to raise_error(described_class::InvalidEntitlementProviderResult)
  end

  def user_selection
    DiscourseUserCosmetics::UserSelection.find_by!(user_id: user.id)
  end
end
