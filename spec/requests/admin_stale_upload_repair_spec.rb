# frozen_string_literal: true

RSpec.describe DiscourseUserCosmetics::AdminItemsController, type: :request do
  fab!(:admin)

  before do
    enable_current_plugin
    sign_in(admin)
  end

  def dangling_upload_id(offset = 0)
    Upload.maximum(:id).to_i + 100_000 + offset
  end

  it "does not round-trip dangling upload IDs and lets an admin replace stale profile layers" do
    item = DiscourseUserCosmetics::Item.create!(kind: "profile_effect", name: "Legacy effect")
    item.update_column(:image_upload_id, dangling_upload_id)

    now = Time.zone.now
    DiscourseUserCosmetics::EffectLayer.insert_all!(
      [
        {
          item_id: item.id,
          anchor: "top",
          stack_order: "front",
          image_upload_id: dangling_upload_id(1),
          image_url: nil,
          created_at: now,
          updated_at: now,
        },
      ],
    )

    get "/admin/plugins/user-cosmetics/items.json", params: { kind: "profile_effect" }

    expect(response).to be_successful
    serialized = response.parsed_body.fetch("items").find { |entry| entry["id"] == item.id }
    expect(serialized).to include("image_upload_id" => nil, "raw_image_url" => nil)
    expect(serialized.fetch("layers")).to be_empty

    fresh_upload = Fabricate(:upload, extension: "webp")

    put "/admin/plugins/user-cosmetics/items/#{item.id}.json",
        params: {
          item: {
            name: serialized.fetch("name"),
            image_upload_id: serialized["image_upload_id"],
            image_url: serialized["raw_image_url"],
            layers: [
              {
                anchor: "full",
                stack_order: "front",
                image_upload_id: fresh_upload.id,
              },
            ],
          },
        }

    expect(response).to be_successful

    item.reload
    expect(item.image_upload_id).to be_nil
    expect(item.effect_layers.count).to eq(1)

    layer = item.effect_layers.first
    expect(layer).to have_attributes(
      anchor: "full",
      stack_order: "front",
      image_upload_id: fresh_upload.id,
      image_url: nil,
    )
    expect(
      UploadReference.exists?(
        upload_id: fresh_upload.id,
        target_type: layer.class.name,
        target_id: layer.id,
      ),
    ).to eq(true)
  end

  it "falls back to a safe manual URL when a legacy layer upload ID is dangling" do
    item = DiscourseUserCosmetics::Item.create!(kind: "profile_effect", name: "Fallback effect")
    layer =
      item.effect_layers.create!(
        anchor: "left",
        stack_order: "back",
        image_url: "https://example.com/legacy-layer.webp",
      )
    layer.update_column(:image_upload_id, dangling_upload_id)

    get "/admin/plugins/user-cosmetics/items.json", params: { kind: "profile_effect" }

    expect(response).to be_successful
    serialized_item = response.parsed_body.fetch("items").find { |entry| entry["id"] == item.id }
    serialized_layer = serialized_item.fetch("layers").sole
    expect(serialized_layer).to include(
      "image_upload_id" => nil,
      "raw_image_url" => "https://example.com/legacy-layer.webp",
      "image_url" => "https://example.com/legacy-layer.webp",
    )

    put "/admin/plugins/user-cosmetics/items/#{item.id}.json",
        params: {
          item: {
            layers: [
              {
                anchor: serialized_layer.fetch("anchor"),
                stack_order: serialized_layer.fetch("stack_order"),
                image_upload_id: serialized_layer["image_upload_id"],
                image_url: serialized_layer.fetch("raw_image_url"),
              },
            ],
          },
        }

    expect(response).to be_successful

    repaired_layer = item.reload.effect_layers.sole
    expect(repaired_layer.image_upload_id).to be_nil
    expect(repaired_layer.image_url).to eq("https://example.com/legacy-layer.webp")
  end

  it "still rejects an explicitly supplied upload ID that does not exist" do
    item = DiscourseUserCosmetics::Item.create!(kind: "profile_effect", name: "Strict effect")

    put "/admin/plugins/user-cosmetics/items/#{item.id}.json",
        params: {
          item: {
            layers: [
              {
                anchor: "full",
                stack_order: "front",
                image_upload_id: dangling_upload_id,
              },
            ],
          },
        }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(item.reload.effect_layers).to be_empty
  end
end
