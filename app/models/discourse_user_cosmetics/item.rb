# frozen_string_literal: true

module ::DiscourseUserCosmetics
  class Item < ActiveRecord::Base
    self.table_name = "discourse_user_cosmetics_items"

    KINDS = %w[avatar_frame nameplate card_decoration profile_effect].freeze
    SITE_SETTING_FOR_KIND = {
      "avatar_frame" => :discourse_user_cosmetics_avatar_frames_enabled,
      "nameplate" => :discourse_user_cosmetics_nameplates_enabled,
      "card_decoration" => :discourse_user_cosmetics_card_decorations_enabled,
      "profile_effect" => :discourse_user_cosmetics_profile_effects_enabled,
    }.freeze
    HEX_COLOR_REGEX = /\A#[0-9a-fA-F]{3}([0-9a-fA-F]{3}([0-9a-fA-F]{2})?)?\z/
    DEFAULT_EFFECT_INNER_WIDTH = 1200

    has_many :item_groups, class_name: "DiscourseUserCosmetics::ItemGroup", foreign_key: :item_id,
                            dependent: :destroy
    has_many :groups, through: :item_groups
    has_many :user_items, class_name: "DiscourseUserCosmetics::UserItem", foreign_key: :item_id,
                           dependent: :destroy
    has_many :effect_layers, -> { order(:anchor, :stack_order) },
             class_name: "DiscourseUserCosmetics::EffectLayer", foreign_key: :item_id, dependent: :destroy
    has_many :upload_references, as: :target, dependent: :destroy

    belongs_to :image_upload, class_name: "::Upload", optional: true
    belongs_to :created_by, class_name: "::User", optional: true

    validates :kind, inclusion: { in: KINDS }
    validates :name, presence: true, length: { maximum: 100 }
    validates :slug, length: { maximum: 120 }
    validates :description, length: { maximum: 500 }, allow_blank: true
    validates :gradient_from, :gradient_to, :glow_color, :rarity_color,
              format: {
                with: HEX_COLOR_REGEX,
              }, allow_blank: true
    validates :rarity_label, length: { maximum: 40 }, allow_blank: true
    validates :image_url, length: { maximum: 1000 }, allow_blank: true
    validates :effect_inner_width, numericality: { only_integer: true, in: 200..4000 }, allow_nil: true
    validates :effect_overflow_top, :effect_overflow_bottom, :effect_overflow_horizontal,
              :effect_side_offset_top, :effect_side_offset_bottom,
              numericality: {
                only_integer: true, in: 0..2000,
              }, allow_nil: true
    validate :slug_unique_within_kind
    validate :validate_image_asset

    before_validation :ensure_slug
    after_save :sync_image_upload_reference, if: :saved_change_to_image_upload_id?

    scope :enabled, -> { where(enabled: true) }
    scope :for_kind, ->(kind) { where(kind: kind) }
    scope :ordered, -> { order(:sort_order, :id) }

    def self.kind_enabled?(kind)
      setting = SITE_SETTING_FOR_KIND[kind.to_s]
      setting && SiteSetting.public_send(setting)
    end

    # An item with no group restrictions is available to every logged in user.
    def public_access?
      !item_groups.exists?
    end

    def resolved_image_url
      return image_upload.url if image_upload
      image_url.presence
    end

    def resolved_effect_inner_width
      effect_inner_width || DEFAULT_EFFECT_INNER_WIDTH
    end

    # Central permission check: is this user allowed to select/wear this item?
    def usable_by?(user)
      return false unless user
      return true if is_default?
      return true if public_access?
      return true if item_groups.where(group_id: user.group_ids).exists?
      user_items.where(user_id: user.id).exists?
    end

    def self.usable_item_ids_for(user, kind)
      return [] unless user && kind_enabled?(kind)
      for_kind(kind).enabled.select { |item| item.usable_by?(user) }.map(&:id)
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

    def slug_unique_within_kind
      return if slug.blank? || kind.blank?
      scope = self.class.where(kind: kind, slug: slug)
      scope = scope.where.not(id: id) if persisted?
      errors.add(:slug, :taken) if scope.exists?
    end

    def ensure_slug
      return if slug.present?
      base = name.to_s.parameterize
      base = "item" if base.blank?
      candidate = base
      i = 2
      while self.class.where(kind: kind).where.not(id: id || 0).exists?(slug: candidate)
        candidate = "#{base}-#{i}"
        i += 1
      end
      self.slug = candidate
    end
  end
end
