# frozen_string_literal: true

RSpec.describe "cosmetic user reference integrity" do
  before { enable_current_plugin }

  it "cleans deleted-user ownership while preserving catalog and recipient grants" do
    deleted_user = Fabricate(:user)
    recipient = Fabricate(:user)
    frame =
      DiscourseUserCosmetics::Item.create!(
        kind: "avatar_frame",
        name: "Deleted creator frame",
        created_by: deleted_user,
      )
    owned_item = DiscourseUserCosmetics::Item.create!(kind: "nameplate", name: "Deleted owner plate")

    DiscourseUserCosmetics::UserItem.create!(
      user: deleted_user,
      item: owned_item,
      granted_by: deleted_user,
    )
    recipient_grant =
      DiscourseUserCosmetics::UserItem.create!(
        user: recipient,
        item: frame,
        granted_by: deleted_user,
      )
    DiscourseUserCosmetics::SelectionService.select!(
      user: deleted_user,
      kind: "avatar_frame",
      item_id: frame.id,
    )

    previous_stylesheet_version = DiscourseUserCosmetics::Presenter.stylesheet_version
    deleted_user_id = deleted_user.id

    deleted_user.destroy!

    expect(DiscourseUserCosmetics::UserSelection.where(user_id: deleted_user_id)).to be_empty
    expect(DiscourseUserCosmetics::UserItem.where(user_id: deleted_user_id)).to be_empty
    expect(recipient_grant.reload.granted_by_id).to be_nil
    expect(frame.reload.created_by_id).to be_nil
    expect(DiscourseUserCosmetics::Item.where(id: frame.id)).to exist
    expect(DiscourseUserCosmetics::Presenter.stylesheet_version).not_to eq(previous_stylesheet_version)
  end

  it "does not invalidate the shared stylesheet when the deleted user had no stylesheet selection" do
    deleted_user = Fabricate(:user)
    item = DiscourseUserCosmetics::Item.create!(kind: "card_decoration", name: "Deleted user's card")
    DiscourseUserCosmetics::SelectionService.select!(
      user: deleted_user,
      kind: "card_decoration",
      item_id: item.id,
    )

    previous_stylesheet_version = DiscourseUserCosmetics::Presenter.stylesheet_version

    deleted_user.destroy!

    expect(DiscourseUserCosmetics::Presenter.stylesheet_version).to eq(previous_stylesheet_version)
  end
end
