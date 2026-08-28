# frozen_string_literal: true

RSpec.describe DiscourseUserCosmetics::SelectionService do
  fab!(:user)

  before { enable_current_plugin }

  it "publishes a privacy-safe live marker when a selection changes" do
    item =
      DiscourseUserCosmetics::Item.create!(
        kind: "card_decoration",
        name: "Live card decoration",
        image_url: "https://example.com/live-card.webp",
      )

    messages =
      MessageBus.track_publish do
        described_class.select!(
          user: user,
          kind: "card_decoration",
          item_id: item.id,
        )
      end

    message = messages.find { |candidate| candidate.channel == described_class::CHANGE_CHANNEL }

    expect(message).to be_present
    expect(message.data).to eq(user_id: user.id, kind: "card_decoration")
    expect(message.data.keys).to contain_exactly(:user_id, :kind)
  end

  it "does not publish another live marker when the selection is unchanged" do
    item =
      DiscourseUserCosmetics::Item.create!(
        kind: "avatar_frame",
        name: "Stable frame",
        image_url: "https://example.com/stable-frame.webp",
      )

    described_class.select!(user: user, kind: "avatar_frame", item_id: item.id)

    messages =
      MessageBus.track_publish do
        described_class.select!(user: user, kind: "avatar_frame", item_id: item.id)
      end

    live_messages =
      messages.select { |candidate| candidate.channel == described_class::CHANGE_CHANNEL }
    expect(live_messages).to be_empty
  end
end
