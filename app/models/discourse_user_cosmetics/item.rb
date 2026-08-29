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
    validate :kind_cannot_change, on: :update

    before_validation :ensure_slug
    before_destroy :clear_active_selections
    before_destroy :clear_saved_loadout_references
    after_destroy :bump_cosmetics_cache
    after_save :sync_image_upload_reference, if: :saved_change_to_image_upload_id?
    after_update_commit :clear_invalid_active_selections_after_access_change,
                        if: :access_restricting_update?

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
      return image_url if DiscourseUserCosmetics::AssetPolicy.valid_url?(image_url)

      nil
    end

    def resolved_effect_inner_width
      effect_inner_width || DEFAULT_EFFECT_INNER_WIDTH
    end

    # Central permission check: is this user allowed to select/wear this item?
    # Group membership is intentionally read from GroupUser rather than the
    # user association so a long-lived User instance cannot retain a revoked
    # entitlement through cached group_ids.
    def usable_by?(user)
      return false unless user
      return true if is_default?
      return true if public_access?
      return true if item_groups.where(group_id: ::GroupUser.where(user_id: user.id).select(:group_id)).exists?
      user_items.where(user_id: user.id).exists?
    end

    def self.usable_item_ids_for(user, kind)
      return [] unless user && kind_enabled?(kind)
      for_kind(kind).enabled.select { |item| item.usable_by?(user) }.map(&:id)
    end

    private

    def access_restricting_update?
      disabled_now = saved_change_to_enabled? && !enabled?
      default_removed = saved_change_to_is_default? && !is_default?
      disabled_now || default_removed
    end

    def clear_invalid_active_selections_after_access_change
      DiscourseUserCosmetics::SelectionService.clear_invalid_for_item!(self)
    end

    def clear_active_selections
      DiscourseUserCosmetics::SelectionService.clear_item!(self, bump: false)
    end

    def clear_saved_loadout_references
      DiscourseUserCosmetics::Loadout.clear_item!(self)
    end

    def bump_cosmetics_cache
      DiscourseUserCosmetics::Presenter.bump_version!
    end

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

    def kind_cannot_change
      errors.add(:kind, :invalid) if will_save_change_to_kind?
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

# == Schema Information
#
# Table name: discourse_user_cosmetics_items
#
#  id                         :bigint           not null, primary key
#  description                :text
#  effect_inner_width         :integer
#  effect_overflow_bottom     :integer
#  effect_overflow_horizontal :integer
#  effect_overflow_top        :integer
#  effect_side_offset_bottom  :integer          default(0), not null
#  effect_side_offset_top     :integer          default(0), not null
#  enabled                    :boolean          default(TRUE), not null
#  glow_color                 :string(20)
#  gradient_from              :string(20)
#  gradient_to                :string(20)
#  image_url                  :string(1000)
#  is_default                 :boolean          default(FALSE), not null
#  kind                       :string(30)       not null
#  name                       :string(100)      not null
#  rarity_color               :string(20)
#  rarity_label               :string(40)
#  slug                       :string(120)      not null
#  sort_order                 :integer          default(0), not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  created_by_id              :bigint
#  image_upload_id            :bigint
#
# Indexes
#
#  idx_duc_items_kind_enabled_sort  (kind,enabled,sort_order)
#  idx_duc_items_kind_slug          (kind,slug) UNIQUE
#
