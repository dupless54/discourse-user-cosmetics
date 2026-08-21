# frozen_string_literal: true

module ::DiscourseUserCosmetics
  # Builds a plain CSS stylesheet that draws every user's chosen avatar frame
  # as an overlay, keyed off the `data-user-card="username"` attribute that
  # Discourse core already renders on every clickable avatar/username link
  # (post stream, topic list, quotes, notifications, the header, etc).
  #
  # Doing this in pure CSS -- instead of hooking into each individual
  # Ember/widget component that happens to render an avatar -- means frames
  # keep working everywhere Discourse shows an avatar, even if core changes
  # how a particular avatar is rendered internally.
  class CssBuilder
    def self.build_frames_css
      return "/* discourse-user-cosmetics: avatar frames disabled */\n" unless
        SiteSetting.discourse_user_cosmetics_avatar_frames_enabled

      overhang = SiteSetting.discourse_user_cosmetics_frame_overhang_percent.to_i.clamp(0, 60)
      inset_value = "-#{overhang}%"

      css = +"/* discourse-user-cosmetics: generated avatar frame overlays */\n"
      css << ".duc-avatar-frame-target { position: relative !important; display: inline-block !important; }\n"
      css << ".duc-avatar-frame-target::after {\n"
      css << "  content: \"\";\n"
      css << "  position: absolute;\n"
      css << "  inset: #{inset_value};\n"
      css << "  background-repeat: no-repeat;\n"
      css << "  background-position: center;\n"
      css << "  background-size: contain;\n"
      css << "  pointer-events: none;\n"
      css << "  z-index: 2;\n"
      css << "}\n\n"

      DiscourseUserCosmetics::UserSelection
        .where.not(avatar_frame_item_id: nil)
        .includes(:user, :avatar_frame_item)
        .find_each(batch_size: 500) do |selection|
        user = selection.user
        item = selection.avatar_frame_item
        next unless user && item
        next unless item.enabled? && item.kind == "avatar_frame"
        next unless item.usable_by?(user)

        image = item.resolved_image_url
        next if image.blank?

        uname = escape_css_string(user.username_lower)
        image_css = escape_css_url(image)

        # Avatar kutusunu güvene alıyoruz (display ve position kurallarını zorluyoruz)
        css << %([data-user-card="#{uname}"] { position: relative !important; display: inline-block !important; }\n)
        css << %([data-user-card="#{uname}"]::after {\n)
        css << "  content: \"\";\n"
        css << "  position: absolute;\n"
        css << "  inset: #{inset_value};\n"
        css << "  background-image: url(\"#{image_css}\");\n"
        css << "  background-repeat: no-repeat;\n"
        css << "  background-position: center;\n"
        css << "  background-size: contain;\n"
        css << "  pointer-events: none;\n"
        css << "  z-index: 2;\n"
        css << "}\n"
        
        # Etiketlenen (mention) isimler için de aynısını yapıyoruz
        css << %(a.mention[href="/u/#{uname}"] { position: relative !important; display: inline-block !important; }\n)
        css << %(a.mention[href="/u/#{uname}"]::after {\n)
        css << "  content: \"\";\n"
        css << "  position: absolute;\n"
        css << "  inset: #{inset_value};\n"
        css << "  background-image: url(\"#{image_css}\");\n"
        css << "  background-repeat: no-repeat;\n"
        css << "  background-position: center;\n"
        css << "  background-size: contain;\n"
        css << "  pointer-events: none;\n"
        css << "  z-index: 2;\n"
        css << "}\n\n"
      end

      css
    end

    def self.escape_css_string(str)
      str.to_s.gsub(/["\\]/) { |c| "\\#{c}" }
    end

    def self.escape_css_url(str)
      str.to_s.gsub('"', '\\"')
    end
  end
end