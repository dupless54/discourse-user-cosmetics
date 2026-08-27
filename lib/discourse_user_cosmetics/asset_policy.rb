# frozen_string_literal: true

require "uri"

module ::DiscourseUserCosmetics
  class AssetPolicy
    ALLOWED_UPLOAD_EXTENSIONS = %w[png jpg jpeg gif webp].freeze
    SAFE_RELATIVE_PREFIXES = %w[/uploads/ /plugins/discourse-user-cosmetics/].freeze
    UNSAFE_CSS_STRING_CHARACTERS = /[\x00-\x1F\x7F"\\]/

    def self.validate(record, upload_id:, upload:, url:, attribute: :image_url)
      validate_upload(record, upload_id: upload_id, upload: upload, attribute: attribute)
      validate_url(record, url: url, attribute: attribute)
    end

    def self.valid_url?(url)
      value = url.to_s
      return false if value.blank? || value.match?(UNSAFE_CSS_STRING_CHARACTERS)
      return true if SAFE_RELATIVE_PREFIXES.any? { |prefix| value.start_with?(prefix) }

      uri = URI.parse(value)
      uri.is_a?(URI::HTTPS) && uri.host.present? && uri.userinfo.blank?
    rescue URI::InvalidURIError
      false
    end

    def self.validate_upload(record, upload_id:, upload:, attribute:)
      return if upload_id.blank?

      unless upload
        record.errors.add(attribute, I18n.t("discourse_user_cosmetics.errors.upload_missing"))
        return
      end

      extension = upload.extension.to_s.downcase
      unless ALLOWED_UPLOAD_EXTENSIONS.include?(extension)
        record.errors.add(attribute, I18n.t("discourse_user_cosmetics.errors.unsupported_image_format"))
      end

      max_kb = SiteSetting.discourse_user_cosmetics_max_image_kb.to_i
      if max_kb.positive? && upload.filesize.to_i > max_kb.kilobytes
        record.errors.add(
          attribute,
          I18n.t("discourse_user_cosmetics.errors.image_too_large", max_kb: max_kb),
        )
      end
    end
    private_class_method :validate_upload

    def self.validate_url(record, url:, attribute:)
      return if url.blank?
      return if valid_url?(url)

      record.errors.add(attribute, I18n.t("discourse_user_cosmetics.errors.invalid_image_url"))
    end
    private_class_method :validate_url
  end
end
