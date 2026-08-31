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

        stylesheet_selections(kind: "avatar_frame", item_association: :avatar_frame_item).find_each(
          batch_size: 500,
        ) do |selection|
          user = selection.user
          item = selection.avatar_frame_item
          next unless user && item

          image = item.resolved_image_url
          next if image.blank?

          image_css = escape_css_url(image)
          post_avatar_class = "duc-avatar-frame-user-#{user.id}"

          # Current Discourse exposes `post-avatar-class` as a value transformer.
          # The client adds this stable numeric user-id class to `.topic-avatar`,
          # so generated CSS no longer depends on username attributes or `:has()`.
          css << %(.topic-avatar.#{post_avatar_class} .post-avatar { position: relative !important; display: inline-block !important; }\n)
          css << %(.topic-avatar.#{post_avatar_class} .post-avatar::after {\n  content: \"\";\n  position: absolute;\n  inset: #{inset_value};\n  background-image: url(\"#{image_css}\");\n  background-repeat: no-repeat;\n  background-position: center;\n  background-size: contain;\n  pointer-events: none;\n  z-index: 2;\n}\n)
        end
      end

      # ==========================================
      # 2. İSİM PLAKALARI (Metin Arkası Animasyon)
      # ==========================================
      if SiteSetting.discourse_user_cosmetics_nameplates_enabled
        css << "/* --- Username Nameplates --- */\n"

        stylesheet_selections(kind: "nameplate", item_association: :nameplate_item).find_each(
          batch_size: 500,
        ) do |selection|
          user = selection.user
          item = selection.nameplate_item
          next unless user && item

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

    def self.stylesheet_selections(kind:, item_association:)
      selection_table = DiscourseUserCosmetics::UserSelection.table_name
      item_table = DiscourseUserCosmetics::Item.table_name
      item_group_table = DiscourseUserCosmetics::ItemGroup.table_name
      user_item_table = DiscourseUserCosmetics::UserItem.table_name
      field = DiscourseUserCosmetics::UserSelection.field_for(kind)

      DiscourseUserCosmetics::UserSelection
        .where.not(field => nil)
        .joins(
          "INNER JOIN #{item_table} AS selected_cosmetic_items " \
            "ON selected_cosmetic_items.id = #{selection_table}.#{field}",
        )
        .where("selected_cosmetic_items.kind = ? AND selected_cosmetic_items.enabled = TRUE", kind)
        .where(<<~SQL)
          selected_cosmetic_items.is_default = TRUE
          OR NOT EXISTS (
            SELECT 1
            FROM #{item_group_table} AS cosmetic_item_groups
            WHERE cosmetic_item_groups.item_id = selected_cosmetic_items.id
          )
          OR EXISTS (
            SELECT 1
            FROM #{item_group_table} AS cosmetic_group_access
            INNER JOIN group_users AS cosmetic_group_users
              ON cosmetic_group_users.group_id = cosmetic_group_access.group_id
            WHERE cosmetic_group_access.item_id = selected_cosmetic_items.id
              AND cosmetic_group_users.user_id = #{selection_table}.user_id
          )
          OR EXISTS (
            SELECT 1
            FROM #{user_item_table} AS cosmetic_user_items
            WHERE cosmetic_user_items.item_id = selected_cosmetic_items.id
              AND cosmetic_user_items.user_id = #{selection_table}.user_id
          )
        SQL
        .includes(:user, item_association => :image_upload)
    end
    private_class_method :stylesheet_selections
  end
end
