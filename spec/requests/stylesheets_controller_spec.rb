# frozen_string_literal: true

RSpec.describe DiscourseUserCosmetics::StylesheetsController, type: :request do
  fab!(:user)

  before { enable_current_plugin }

  it "revalidates cached CSS after a selected group entitlement is removed" do
    group = Fabricate(:group)
    group.add(user)
    item =
      DiscourseUserCosmetics::Item.create!(
        kind: "avatar_frame",
        name: "Group frame",
        image_url: "https://example.com/group-frame.webp",
      )
    item.item_groups.create!(group: group)

    DiscourseUserCosmetics::SelectionService.select!(
      user: user,
      kind: "avatar_frame",
      item_id: item.id,
    )

    get "/user-cosmetics/frames.css"

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/css")
    expect(response.headers["Cache-Control"]).to include("public", "no-cache", "must-revalidate")
    expect(response.body).to include(user.username_lower)

    first_etag = response.headers.fetch("ETag")

    get "/user-cosmetics/frames.css", headers: { "HTTP_IF_NONE_MATCH" => first_etag }
    expect(response).to have_http_status(:not_modified)

    group.remove(user)

    get "/user-cosmetics/frames.css", headers: { "HTTP_IF_NONE_MATCH" => first_etag }

    expect(response).to have_http_status(:ok)
    expect(response.headers.fetch("ETag")).not_to eq(first_etag)
    expect(response.body).not_to include(user.username_lower)
  end

  it "changes the stylesheet cache identity when a CSS-backed feature gate changes" do
    item =
      DiscourseUserCosmetics::Item.create!(
        kind: "avatar_frame",
        name: "Feature frame",
        image_url: "https://example.com/feature-frame.webp",
      )

    DiscourseUserCosmetics::SelectionService.select!(
      user: user,
      kind: "avatar_frame",
      item_id: item.id,
    )

    get "/user-cosmetics/frames.css"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(user.username_lower)
    first_etag = response.headers.fetch("ETag")

    SiteSetting.discourse_user_cosmetics_avatar_frames_enabled = false

    get "/user-cosmetics/frames.css", headers: { "HTTP_IF_NONE_MATCH" => first_etag }

    expect(response).to have_http_status(:ok)
    expect(response.headers.fetch("ETag")).not_to eq(first_etag)
    expect(response.body).not_to include(user.username_lower)
  end
end
