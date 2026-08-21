# frozen_string_literal: true

module ::DiscourseUserCosmetics
  class UserSelection < ActiveRecord::Base
    self.table_name = "discourse_user_cosmetics_user_selections"

    belongs_to :user, class_name: "::User"
    belongs_to :avatar_frame_item, class_name: "DiscourseUserCosmetics::Item", optional: true
    belongs_to :nameplate_item, class_name: "DiscourseUserCosmetics::Item", optional: true
    belongs_to :card_decoration_item, class_name: "DiscourseUserCosmetics::Item", optional: true

    FIELD_FOR_KIND = {
      "avatar_frame" => :avatar_frame_item_id,
      "nameplate" => :nameplate_item_id,
      "card_decoration" => :card_decoration_item_id,
    }.freeze

    def self.field_for(kind)
      FIELD_FOR_KIND.fetch(kind.to_s)
    end
  end
end
