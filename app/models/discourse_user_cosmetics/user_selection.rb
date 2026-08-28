# frozen_string_literal: true

module ::DiscourseUserCosmetics
  class UserSelection < ActiveRecord::Base
    self.table_name = "discourse_user_cosmetics_user_selections"

    belongs_to :user, class_name: "::User"
    belongs_to :avatar_frame_item, class_name: "DiscourseUserCosmetics::Item", optional: true
    belongs_to :nameplate_item, class_name: "DiscourseUserCosmetics::Item", optional: true
    belongs_to :card_decoration_item, class_name: "DiscourseUserCosmetics::Item", optional: true
    belongs_to :profile_effect_item, class_name: "DiscourseUserCosmetics::Item", optional: true

    FIELD_FOR_KIND = {
      "avatar_frame" => :avatar_frame_item_id,
      "nameplate" => :nameplate_item_id,
      "card_decoration" => :card_decoration_item_id,
      "profile_effect" => :profile_effect_item_id,
    }.freeze

    validate :changed_selections_are_usable

    def self.field_for(kind)
      FIELD_FOR_KIND.fetch(kind.to_s)
    end

    private

    def changed_selections_are_usable
      FIELD_FOR_KIND.each do |kind, field|
        next unless will_save_change_to_attribute?(field)

        item_id = public_send(field)
        next if item_id.blank?

        item = DiscourseUserCosmetics::Item.find_by(id: item_id, kind: kind, enabled: true)
        next if DiscourseUserCosmetics::Item.kind_enabled?(kind) && item && item.usable_by?(user)

        errors.add(field, :invalid)
      end
    end
  end
end
