# frozen_string_literal: true

RSpec.describe DiscourseUserCosmetics do
  before { enable_current_plugin }

  EXPECTED_BIGINT_COLUMNS = {
    "discourse_user_cosmetics_items" => %w[image_upload_id created_by_id],
    "discourse_user_cosmetics_item_groups" => %w[item_id group_id],
    "discourse_user_cosmetics_user_items" => %w[user_id item_id granted_by_id],
    "discourse_user_cosmetics_user_selections" => %w[
      user_id
      avatar_frame_item_id
      nameplate_item_id
      card_decoration_item_id
      profile_effect_item_id
    ],
    "discourse_user_cosmetics_effect_layers" => %w[item_id image_upload_id],
  }.freeze

  it "uses bigint-width columns for every record relationship" do
    connection = ActiveRecord::Base.connection

    EXPECTED_BIGINT_COLUMNS.each do |table, column_names|
      columns = connection.columns(table).index_by(&:name)

      column_names.each do |column_name|
        expect(columns.fetch(column_name).limit).to eq(8), "expected #{table}.#{column_name} to be bigint"
      end
    end
  end
end
