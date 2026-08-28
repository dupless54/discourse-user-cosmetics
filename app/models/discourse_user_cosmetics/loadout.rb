# frozen_string_literal: true

module ::DiscourseUserCosmetics
  class Loadout < ActiveRecord::Base
    self.table_name = "discourse_user_cosmetics_loadouts"

    MAX_NAME_LENGTH = 80
    SLOT_FIELD_FOR_KIND = DiscourseUserCosmetics::UserSelection::FIELD_FOR_KIND.freeze

    belongs_to :user, class_name: "::User"
    belongs_to :avatar_frame_item, class_name: "DiscourseUserCosmetics::Item", optional: true
    belongs_to :nameplate_item, class_name: "DiscourseUserCosmetics::Item", optional: true
    belongs_to :card_decoration_item, class_name: "DiscourseUserCosmetics::Item", optional: true
    belongs_to :profile_effect_item, class_name: "DiscourseUserCosmetics::Item", optional: true

    before_validation :normalize_name

    validates :name, presence: true, length: { maximum: MAX_NAME_LENGTH }
    validate :slot_items_match_kinds

    scope :ordered, -> { order(updated_at: :desc, id: :desc) }

    def selection_item_ids
      SLOT_FIELD_FOR_KIND.transform_values { |field| public_send(field) }
    end

    def self.clear_item!(item)
      return 0 unless item && SLOT_FIELD_FOR_KIND.key?(item.kind.to_s)

      field = SLOT_FIELD_FOR_KIND.fetch(item.kind.to_s)
      where(field => item.id).update_all(field => nil, updated_at: Time.zone.now)
    end

    private

    def normalize_name
      self.name = name.to_s.strip
    end

    def slot_items_match_kinds
      SLOT_FIELD_FOR_KIND.each do |kind, field|
        item_id = public_send(field)
        next if item_id.blank?

        item = public_send(kind_item_association(kind))
        errors.add(field, :invalid) unless item&.kind == kind
      end
    end

    def kind_item_association(kind)
      "#{kind}_item"
    end
  end
end
