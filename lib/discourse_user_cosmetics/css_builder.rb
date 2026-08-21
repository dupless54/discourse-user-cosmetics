# frozen_string_literal: true

module ::DiscourseUserCosmetics
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

        # 1. Konular ve Mesajlar (SADECE İÇİNDE AVATAR RESMİ OLANLARI SEÇER, METİNLERİ ELLER)
        css << %([data-user-card="#{uname}" i]:has(img.avatar) { position: relative !important; display: inline-block !important; }\n)
        css << %([data-user-card="#{uname}" i]:has(img.avatar)::after {\n)
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

        # 2. Kullanıcı Kartındaki (Açılır Pencere) Avatar
        css << %(#user-card .user-card-avatar a[href^="/u/#{uname}" i] { position: relative !important; display: inline-block !important; }\n)
        css << %(#user-card .user-card-avatar a[href^="/u/#{uname}" i]::after {\n)
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

        # 3. Kullanıcı Profil Sayfasındaki Ana Avatar
        # Resmin url yolundan (src) VEYA başlığından (title) eşleştirme yaparak kesin yakalarız
        css << %(.user-profile-avatar:has(img.avatar[src*="/#{uname}/" i]), .user-profile-avatar:has(img.avatar[title="#{uname}" i]) { position: relative !important; display: inline-block !important; }\n)
        css << %(.user-profile-avatar:has(img.avatar[src*="/#{uname}/" i])::after, .user-profile-avatar:has(img.avatar[title="#{uname}" i])::after {\n)
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