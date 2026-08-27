# frozen_string_literal: true

module ::DiscourseUserCosmetics
  class EffectLayer < ActiveRecord::Base
    self.table_name = "discourse_user_cosmetics_effect_layers"

    ANCHORS = %w[top bottom left right full].freeze
    STACK_ORDERS = %w[front back].freeze

    belongs_to :item, class_name: "DiscourseUserCosmetics::Item"
    belongs_to :image_upload, class_name: "::Upload", optional: true
    has_many :upload_references, as: :target, dependent: :destroy

    validates :anchor, inclusion: { in: ANCHORS }
    validates :stack_order, inclusion: { in: STACK_ORDERS }
    validates :image_url, length: { maximum: 1000 }, allow_blank: true
    validates :anchor, uniqueness: { scope: %i[item_id stack_order] }
    validate :validate_image_asset

    after_save :sync_image_upload_reference, if: :saved_change_to_image_upload_id?

    def resolved_image_url
      return image_upload.url if image_upload
      return image_url if DiscourseUserCosmetics::AssetPolicy.valid_url?(image_url)

      nil
    end

    private

    def sync_image_upload_reference
      ::UploadReference.ensure_exist!(upload_ids: [image_upload_id], target: self)
    end

    def validate_image_asset
      DiscourseUserCosmetics::AssetPolicy.validate(
        self,
        upload_id: image_upload_id,
        upload: image_upload,
        url: image_url,
      )
    end
  end
end
