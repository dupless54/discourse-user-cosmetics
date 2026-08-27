# frozen_string_literal: true

require_relative "../../db/migrate/20260827000001_backfill_cosmetic_upload_references"

RSpec.describe BackfillCosmeticUploadReferences do
  before { enable_current_plugin }

  it "backfills existing item and effect-layer uploads idempotently" do
    item_upload = Fabricate(:upload)
    layer_upload = Fabricate(:upload)
    item =
      DiscourseUserCosmetics::Item.create!(
        kind: "profile_effect",
        name: "Legacy effect",
        image_upload: item_upload,
      )
    layer =
      DiscourseUserCosmetics::EffectLayer.create!(
        item: item,
        anchor: "full",
        stack_order: "front",
        image_upload: layer_upload,
      )

    UploadReference.where(
      target_type: "DiscourseUserCosmetics::Item",
      target_id: item.id,
    ).delete_all
    UploadReference.where(
      target_type: "DiscourseUserCosmetics::EffectLayer",
      target_id: layer.id,
    ).delete_all

    migration = described_class.new
    migration.up
    migration.up

    expect(
      UploadReference.where(
        upload_id: item_upload.id,
        target_type: "DiscourseUserCosmetics::Item",
        target_id: item.id,
      ).count,
    ).to eq(1)
    expect(
      UploadReference.where(
        upload_id: layer_upload.id,
        target_type: "DiscourseUserCosmetics::EffectLayer",
        target_id: layer.id,
      ).count,
    ).to eq(1)
  end
end
