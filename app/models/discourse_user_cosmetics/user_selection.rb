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
      changed_slots =
        FIELD_FOR_KIND.filter_map do |kind, field|
          next unless will_save_change_to_attribute?(field)

          item_id = public_send(field)
          next if item_id.blank?

          [kind, field, item_id]
        end
      return if changed_slots.empty?

      items_by_id =
        DiscourseUserCosmetics::Item.enabled
          .where(id: changed_slots.map(&:last).uniq)
          .to_a
          .index_by(&:id)
      valid_slots = []

      changed_slots.each do |kind, field, item_id|
        item = items_by_id[item_id]
        if !DiscourseUserCosmetics::Item.kind_enabled?(kind) || item&.kind != kind
          errors.add(field, :invalid)
          next
        end

        valid_slots << [field, item]
      end

      usable_item_ids =
        DiscourseUserCosmetics::EntitlementResolver.usable_item_ids(
          user: user,
          items: valid_slots.map(&:last),
        )

      valid_slots.each do |field, item|
        errors.add(field, :invalid) unless usable_item_ids.key?(item.id)
      end
    end
  end
end

# == Schema Information
#
# Table name: discourse_user_cosmetics_user_selections
#
#  id                      :bigint           not null, primary key
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  avatar_frame_item_id    :bigint
#  card_decoration_item_id :bigint
#  nameplate_item_id       :bigint
#  profile_effect_item_id  :bigint
#  user_id                 :bigint           not null
#
# Indexes
#
#  idx_duc_user_selections_user  (user_id) UNIQUE
#
