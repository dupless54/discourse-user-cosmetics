# frozen_string_literal: true

RSpec.describe DiscourseUserCosmetics::AssetPolicy do
  before { enable_current_plugin }

  it "accepts plugin-owned paths, upload paths, and HTTPS URLs" do
    expect(described_class.valid_url?("/plugins/discourse-user-cosmetics/default-cosmetics/frame-gold.png")).to eq(true)
    expect(described_class.valid_url?("/uploads/default/original/1X/example.webp")).to eq(true)
    expect(described_class.valid_url?("https://cdn.example.com/cosmetics/frame.webp?v=2")).to eq(true)
  end

  it "rejects unsafe schemes and CSS or HTML breaking URL characters" do
    expect(described_class.valid_url?("javascript:alert(1)")).to eq(false)
    expect(described_class.valid_url?("data:image/svg+xml,<svg></svg>")).to eq(false)
    expect(described_class.valid_url?("http://example.com/frame.webp")).to eq(false)
    expect(described_class.valid_url?("https://example.com/frame\".webp")).to eq(false)
    expect(described_class.valid_url?("https://example.com/</style>.webp")).to eq(false)
    expect(described_class.valid_url?("https://user:pass@example.com/frame.webp")).to eq(false)
  end

  it "inherits Discourse's image size limit when the plugin-specific cap is zero" do
    SiteSetting.discourse_user_cosmetics_max_image_kb = 0
    SiteSetting.max_image_size_kb = 4096

    upload = Fabricate(:upload, extension: "webp")
    upload.update_column(:filesize, 3072.kilobytes)

    item =
      DiscourseUserCosmetics::Item.new(
        kind: "avatar_frame",
        name: "Inherited limit frame",
        image_upload: upload,
      )

    expect(described_class.maximum_image_kb).to eq(4096)
    expect(item).to be_valid
  end

  it "keeps an explicit plugin image cap as a stricter optional limit" do
    SiteSetting.discourse_user_cosmetics_max_image_kb = 2048
    SiteSetting.max_image_size_kb = 4096

    upload = Fabricate(:upload, extension: "webp")
    upload.update_column(:filesize, 3072.kilobytes)

    item =
      DiscourseUserCosmetics::Item.new(
        kind: "avatar_frame",
        name: "Plugin capped frame",
        image_upload: upload,
      )

    expect(described_class.maximum_image_kb).to eq(2048)
    expect(item).not_to be_valid
    expect(item.errors[:image_url]).to be_present
  end

  it "rejects missing, unsupported, and oversized uploads" do
    SiteSetting.discourse_user_cosmetics_max_image_kb = 32

    missing =
      DiscourseUserCosmetics::Item.new(
        kind: "avatar_frame",
        name: "Missing upload",
        image_upload_id: Upload.maximum(:id).to_i + 10_000,
      )
    expect(missing).not_to be_valid
    expect(missing.errors[:image_url]).to be_present

    unsupported_upload = Fabricate(:upload, extension: "svg")
    unsupported =
      DiscourseUserCosmetics::Item.new(
        kind: "avatar_frame",
        name: "Unsupported upload",
        image_upload: unsupported_upload,
      )
    expect(unsupported).not_to be_valid
    expect(unsupported.errors[:image_url]).to be_present

    oversized_upload = Fabricate(:upload, extension: "webp", filesize: 33.kilobytes)
    oversized =
      DiscourseUserCosmetics::EffectLayer.new(
        item: DiscourseUserCosmetics::Item.create!(kind: "profile_effect", name: "Effect"),
        anchor: "full",
        stack_order: "front",
        image_upload: oversized_upload,
      )
    expect(oversized).not_to be_valid
    expect(oversized.errors[:image_url]).to be_present
  end

  it "does not render an unsafe manual URL that predates the validation policy" do
    item =
      DiscourseUserCosmetics::Item.create!(
        kind: "avatar_frame",
        name: "Legacy frame",
        image_url: "https://example.com/safe.webp",
      )
    item.update_column(:image_url, "javascript:alert(1)")

    expect(item.reload.resolved_image_url).to be_nil

    effect = DiscourseUserCosmetics::Item.create!(kind: "profile_effect", name: "Legacy effect")
    layer =
      effect.effect_layers.create!(
        anchor: "full",
        stack_order: "front",
        image_url: "https://example.com/safe.webp",
      )
    layer.update_column(:image_url, "https://example.com/</style>.webp")

    expect(layer.reload.resolved_image_url).to be_nil
  end
end
