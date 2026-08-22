# frozen_string_literal: true

module ::DiscourseUserCosmetics
  # A single positioned layer for a "profile_effect" item, mirroring Discord's
  # profile-effect JSON layer objects ({ anchor, order, id }).
  class EffectLayer < ActiveRecord::Base
    self.table_name = "discourse_user_cosmetics_effect_layers"

    # "full" (Tam Çerçeve) yönünü sisteme ekledik!
    ANCHORS = %w[top bottom left right full].freeze
    STACK_ORDERS = %w[front back].freeze

    belongs_to :item, class_name: "DiscourseUserCosmetics::Item"
    belongs_to :image_upload, class_name: "::Upload", optional: true

    validates :anchor, inclusion: { in: ANCHORS }
    validates :stack_order, inclusion: { in: STACK_ORDERS }

    def resolved_image_url
      return image_upload.url if image_upload
      image_url.presence
    end
  end
end