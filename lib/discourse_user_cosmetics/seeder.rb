# frozen_string_literal: true

module ::DiscourseUserCosmetics
  # Ships a small "starter pack" so the feature is immediately visible and
  # testable after installing the plugin, instead of an empty admin screen.
  # Uses static image_url values pointing at the plugin's own /public folder
  # (symlinked by Discourse into /plugins/discourse-user-cosmetics/...) so
  # seeding never depends on the Upload/S3 pipeline being configured yet.
  class Seeder
    BASE_URL = "/plugins/discourse-user-cosmetics/default-cosmetics"

    def self.seed_defaults!
      return if DiscourseUserCosmetics::Item.exists?

      seed_frames!
      seed_nameplates!
      seed_card_decorations!
    rescue => e
      Rails.logger.warn("[discourse-user-cosmetics] default seed skipped (#{e.class}: #{e.message})")
    end

    def self.seed_frames!
      [
        { name: "Altın Halka", file: "frame-gold.png", rarity_label: "Efsanevi", rarity_color: "#f4b942" },
        { name: "Neon Mor", file: "frame-neon-purple.png", rarity_label: "Nadir", rarity_color: "#b24bf3" },
        { name: "Alev Çemberi", file: "frame-fire.png", rarity_label: "Nadir", rarity_color: "#ff6b35" },
        { name: "Buz Mavisi", file: "frame-ice.png", rarity_label: "Sıradan", rarity_color: "#4fd3e8" },
        { name: "Orman Yaprağı", file: "frame-leaf.png", rarity_label: "Sıradan", rarity_color: "#4caf50" },
      ].each_with_index do |f, i|
        DiscourseUserCosmetics::Item.create!(
          kind: "avatar_frame",
          name: f[:name],
          image_url: "#{BASE_URL}/#{f[:file]}",
          rarity_label: f[:rarity_label],
          rarity_color: f[:rarity_color],
          sort_order: i,
          is_default: i.zero?,
        )
      end
    end

    def self.seed_nameplates!
      [
        { name: "Gün Batımı", gradient_from: "#ff512f", gradient_to: "#f09819" },
        { name: "Okyanus", gradient_from: "#2193b0", gradient_to: "#6dd5ed" },
        { name: "Zümrüt", gradient_from: "#11998e", gradient_to: "#38ef7d" },
        { name: "Gece Yarısı", gradient_from: "#0f2027", gradient_to: "#2c5364" },
        { name: "Pembe Düş", gradient_from: "#ee9ca7", gradient_to: "#ffdde1" },
      ].each_with_index do |n, i|
        DiscourseUserCosmetics::Item.create!(
          kind: "nameplate",
          name: n[:name],
          gradient_from: n[:gradient_from],
          gradient_to: n[:gradient_to],
          sort_order: i,
          is_default: i.zero?,
        )
      end
    end

    def self.seed_card_decorations!
      [
        { name: "Yıldız Tozu", file: "card-stardust.png" },
        { name: "Orman", file: "card-forest.png" },
        { name: "Volkanik", file: "card-lava.png" },
      ].each_with_index do |d, i|
        DiscourseUserCosmetics::Item.create!(
          kind: "card_decoration",
          name: d[:name],
          image_url: "#{BASE_URL}/#{d[:file]}",
          sort_order: i,
          is_default: i.zero?,
        )
      end
    end
  end
end
