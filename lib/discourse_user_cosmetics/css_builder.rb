# frozen_string_literal: true

module ::DiscourseUserCosmetics
  class CssBuilder
    def self.build_frames_css
      css = +"/* discourse-user-cosmetics: generated styles */\n\n"

      # ==========================================
      # 1. AVATAR ÇERÇEVELERİ
      # ==========================================
      if SiteSetting.discourse_user_cosmetics_avatar_frames_enabled
        overhang = SiteSetting.discourse_user_cosmetics_frame_overhang_percent.to_i.clamp(0, 60)
        inset_value = "-#{overhang}%"

        css << "/* --- Avatar Frames --- */\n"
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
          next unless user && item && item.enabled? && item.kind == "avatar_frame" && item.usable_by?(user)

          image = item.resolved_image_url
          next if image.blank?

          uname = escape_css_string(user.username_lower)
          image_css = escape_css_url(image)

          # Konular ve Mesajlar
          css << %([data-user-card="#{uname}" i]:has(img.avatar) { position: relative !important; display: inline-block !important; }\n)
          css << %([data-user-card="#{uname}" i]:has(img.avatar)::after {\n  content: \"\";\n  position: absolute;\n  inset: #{inset_value};\n  background-image: url(\"#{image_css}\");\n  background-repeat: no-repeat;\n  background-position: center;\n  background-size: contain;\n  pointer-events: none;\n  z-index: 2;\n}\n)

          # Kart (Açılır Pencere)
          css << %(#user-card .user-card-avatar a[href^="/u/#{uname}" i] { position: relative !important; display: inline-block !important; }\n)
          css << %(#user-card .user-card-avatar a[href^="/u/#{uname}" i]::after {\n  content: \"\";\n  position: absolute;\n  inset: #{inset_value};\n  background-image: url(\"#{image_css}\");\n  background-repeat: no-repeat;\n  background-position: center;\n  background-size: contain;\n  pointer-events: none;\n  z-index: 2;\n}\n)

          # Profil Sayfası
          css << %(.user-profile-avatar:has(img.avatar[src*="/#{uname}/" i]), .user-profile-avatar:has(img.avatar[title="#{uname}" i]) { position: relative !important; display: inline-block !important; }\n)
          css << %(.user-profile-avatar:has(img.avatar[src*="/#{uname}/" i])::after, .user-profile-avatar:has(img.avatar[title="#{uname}" i])::after {\n  content: \"\";\n  position: absolute;\n  inset: #{inset_value};\n  background-image: url(\"#{image_css}\");\n  background-repeat: no-repeat;\n  background-position: center;\n  background-size: contain;\n  pointer-events: none;\n  z-index: 2;\n}\n\n)
        end
      end

      # ==========================================
      # 2. İSİM PLAKALARI (Metin Arkası Animasyon)
      # ==========================================
      if SiteSetting.discourse_user_cosmetics_nameplates_enabled
        css << "/* --- Username Nameplates --- */\n"
        
        DiscourseUserCosmetics::UserSelection
          .where.not(nameplate_item_id: nil)
          .includes(:user, :nameplate_item)
          .find_each(batch_size: 500) do |selection|
          user = selection.user
          item = selection.nameplate_item
          next unless user && item && item.enabled? && item.kind == "nameplate" && item.usable_by?(user)

          uname = escape_css_string(user.username_lower)
          
          bg_css = ""
          if item.resolved_image_url.present?
            bg_css = "background-image: url(\"#{escape_css_url(item.resolved_image_url)}\");"
          elsif item.gradient_from.present? && item.gradient_to.present?
            bg_css = "background-image: linear-gradient(90deg, #{escape_css_string(item.gradient_from)}, #{escape_css_string(item.gradient_to)});"
          else
            next
          end

          # Metinleri saran <a> etiketleri (:not(:has(img.avatar)) ile resimleri dışarıda bırakıyoruz)
          css << %([data-user-card="#{uname}" i]:not(:has(img.avatar)), a.mention[href^="/u/#{uname}" i] {\n)
          css << "  position: relative !important;\n"
          css << "  isolation: isolate; /* Efektin postun arkasına düşmesini %100 engeller */\n"
          css << "  padding: 2px 6px;\n"
          css << "  border-radius: 6px;\n"
          css << "  color: #ffffff !important;\n"
          css << "  text-shadow: 0px 1px 2px #000000, 0px 0px 4px #000000, 0px 0px 8px #000000 !important;\n"
          css << "}\n"

          # ::before sözde elementi ile isim plakasını (GIF/APNG) tam arkaya yerleştiriyoruz
          css << %([data-user-card="#{uname}" i]:not(:has(img.avatar))::before, a.mention[href^="/u/#{uname}" i]::before {\n)
          css << "  content: \"\";\n"
          css << "  position: absolute;\n"
          css << "  inset: 0;\n"
          css << "  #{bg_css}\n"
          css << "  background-size: cover;\n"
          css << "  background-position: center;\n"
          css << "  z-index: -1; /* Sadece ismin arkasında durması için -1 */\n"
          css << "  border-radius: inherit;\n"
          css << "}\n\n"
        end
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