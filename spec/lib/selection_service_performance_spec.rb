# frozen_string_literal: true

RSpec.describe DiscourseUserCosmetics::SelectionService do
  before { enable_current_plugin }

  it "keeps invalid-selection cleanup query count constant as selected users grow" do
    small_item, small_users = build_restricted_selection_set(user_count: 3, name: "Small cleanup card")

    small_changed = nil
    small_queries =
      track_sql_queries do
        small_changed = described_class.clear_invalid_for_item!(small_item, bump: false)
      end

    expect(small_changed).to eq(1)
    expect(selected_user_ids_for(small_item)).to match_array(small_users.first(2).map(&:id))

    large_item, large_users = build_restricted_selection_set(user_count: 30, name: "Large cleanup card")

    large_changed = nil
    large_queries =
      track_sql_queries do
        large_changed = described_class.clear_invalid_for_item!(large_item, bump: false)
      end

    expect(large_changed).to eq(28)
    expect(selected_user_ids_for(large_item)).to match_array(large_users.first(2).map(&:id))
    expect(large_queries.size).to eq(small_queries.size)
  end

  def build_restricted_selection_set(user_count:, name:)
    item = DiscourseUserCosmetics::Item.create!(kind: "card_decoration", name: name)
    users = Array.new(user_count) { Fabricate(:user) }

    users.each do |user|
      described_class.select!(user: user, kind: "card_decoration", item_id: item.id)
    end

    allowed_group = Fabricate(:group)
    allowed_group.add(users.first)
    DiscourseUserCosmetics::UserItem.create!(user: users.second, item: item)
    item.item_groups.create!(group: allowed_group)

    [item, users]
  end

  def selected_user_ids_for(item)
    DiscourseUserCosmetics::UserSelection.where(card_decoration_item_id: item.id).pluck(:user_id)
  end
end
