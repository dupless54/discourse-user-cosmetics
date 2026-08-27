# frozen_string_literal: true

RSpec.describe "DiscourseUserCosmetics upload reference persistence" do
  before { enable_current_plugin }

  def references_for(target)
    UploadReference.where(target_type: target.class.name, target_id: target.id)
  end

  it "keeps item upload references in sync when the image changes or is cleared" do
    first_upload = Fabricate(:upload)
    second_upload = Fabricate(:upload)
    item =
      DiscourseUserCosmetics::Item.create!(
        kind: "avatar_frame",
        name: "Persistent frame",
        image_upload: first_upload,
      )

    expect(references_for(item).pluck(:upload_id)).to eq([first_upload.id])

    item.update!(image_upload: second_upload)

    expect(references_for(item).pluck(:upload_id)).to eq([second_upload.id])

    item.update!(image_upload: nil)

    expect(references_for(item)).to be_empty
  end

  it "keeps profile-effect layer upload references in sync and removes them on destroy" do
    first_upload = Fabricate(:upload)
    second_upload = Fabricate(:upload)
    item =
      DiscourseUserCosmetics::Item.create!(
        kind: "profile_effect",
        name: "Persistent effect",
      )
    layer =
      DiscourseUserCosmetics::EffectLayer.create!(
        item: item,
        anchor: "full",
        stack_order: "front",
        image_upload: first_upload,
      )

    expect(references_for(layer).pluck(:upload_id)).to eq([first_upload.id])

    layer.update!(image_upload: second_upload)

    expect(references_for(layer).pluck(:upload_id)).to eq([second_upload.id])

    layer.destroy!

    expect(references_for(layer)).to be_empty
  end
end
