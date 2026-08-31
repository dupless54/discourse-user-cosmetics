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
    expect(response.headers["Cache-Control"]).to include("public", "no-cache")
    expect(response.headers["Cache-Control"]).not_to include("max-age")
    expect(response.body).to include("duc-avatar-frame-user-#{user.id}")

    first_etag = response.headers.fetch("ETag")

    get "/user-cosmetics/frames.css", headers: { "HTTP_IF_NONE_MATCH" => first_etag }
    expect(response).to have_http_status(:not_modified)

    group.remove(user)

    get "/user-cosmetics/frames.css", headers: { "HTTP_IF_NONE_MATCH" => first_etag }

    expect(response).to have_http_status(:ok)
    expect(response.headers.fetch("ETag")).not_to eq(first_etag)
    expect(response.body).not_to include("duc-avatar-frame-user-#{user.id}")
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
    expect(response.body).to include("duc-avatar-frame-user-#{user.id}")
    first_etag = response.headers.fetch("ETag")

    SiteSetting.discourse_user_cosmetics_avatar_frames_enabled = false

    get "/user-cosmetics/frames.css", headers: { "HTTP_IF_NONE_MATCH" => first_etag }

    expect(response).to have_http_status(:ok)
    expect(response.headers.fetch("ETag")).not_to eq(first_etag)
    expect(response.body).not_to include("duc-avatar-frame-user-#{user.id}")
  end

  it "rebuilds ambient nameplate CSS after the selected user's username changes" do
    item =
      DiscourseUserCosmetics::Item.create!(
        kind: "nameplate",
        name: "Rename plate",
        gradient_from: "#112233",
        gradient_to: "#445566",
      )
    DiscourseUserCosmetics::SelectionService.select!(
      user: user,
      kind: "nameplate",
      item_id: item.id,
    )

    get "/user-cosmetics/frames.css"

    expect(response).to have_http_status(:ok)
    old_username = user.username_lower
    first_etag = response.headers.fetch("ETag")
    expect(response.body).to include("duc-nameplate-post-user-#{user.id}")
    expect(response.body).to include("duc-nameplate-mention-user-#{user.id}")
    expect(response.body).to include(%([data-user-card="#{old_username}" i]))

    new_username = "renamed#{user.id}"
    user.update_columns(username: new_username, username_lower: new_username.downcase)
    DiscourseEvent.trigger(:user_updated, user.reload, %w[username])

    get "/user-cosmetics/frames.css", headers: { "HTTP_IF_NONE_MATCH" => first_etag }

    expect(response).to have_http_status(:ok)
    expect(response.headers.fetch("ETag")).not_to eq(first_etag)
    expect(response.body).to include("duc-nameplate-post-user-#{user.id}")
    expect(response.body).to include(%([data-user-card="#{new_username.downcase}" i]))
    expect(response.body).not_to include(%([data-user-card="#{old_username}" i]))
  end

  it "rebuilds ambient avatar-frame CSS after the selected user's username changes" do
    item =
      DiscourseUserCosmetics::Item.create!(
        kind: "avatar_frame",
        name: "Rename frame",
        image_url: "https://example.com/stable-frame.webp",
      )
    DiscourseUserCosmetics::SelectionService.select!(
      user: user,
      kind: "avatar_frame",
      item_id: item.id,
    )

    get "/user-cosmetics/frames.css"

    expect(response).to have_http_status(:ok)
    old_username = user.username_lower
    first_etag = response.headers.fetch("ETag")
    expect(response.body).to include("duc-avatar-frame-user-#{user.id}")
    expect(response.body).to include(%([data-user-card="#{old_username}" i]))

    new_username = "stable#{user.id}"
    user.update_columns(username: new_username, username_lower: new_username.downcase)
    DiscourseEvent.trigger(:user_updated, user.reload, %w[username])

    get "/user-cosmetics/frames.css", headers: { "HTTP_IF_NONE_MATCH" => first_etag }

    expect(response).to have_http_status(:ok)
    expect(response.headers.fetch("ETag")).not_to eq(first_etag)
    expect(response.body).to include("duc-avatar-frame-user-#{user.id}")
    expect(response.body).to include(%([data-user-card="#{new_username.downcase}" i]))
    expect(response.body).not_to include(%([data-user-card="#{old_username}" i]))
  end

  it "does not invalidate cosmetic CSS for unrelated user updates" do
    item =
      DiscourseUserCosmetics::Item.create!(
        kind: "nameplate",
        name: "Stable plate",
        gradient_from: "#112233",
        gradient_to: "#445566",
      )
    DiscourseUserCosmetics::SelectionService.select!(
      user: user,
      kind: "nameplate",
      item_id: item.id,
    )

    before_version = DiscourseUserCosmetics::Presenter.stylesheet_version

    DiscourseEvent.trigger(:user_updated, user, %w[name])

    expect(DiscourseUserCosmetics::Presenter.stylesheet_version).to eq(before_version)
  end

  it "does not expose generated user CSS anonymously when login is required" do
    item =
      DiscourseUserCosmetics::Item.create!(
        kind: "avatar_frame",
        name: "Private site frame",
        image_url: "https://example.com/private-frame.webp",
      )
    DiscourseUserCosmetics::SelectionService.select!(
      user: user,
      kind: "avatar_frame",
      item_id: item.id,
    )
    SiteSetting.login_required = true

    get "/user-cosmetics/frames.css"

    expect(response).to have_http_status(:found)
    expect(response.headers.fetch("Location")).to include("/login")
    expect(response.body).not_to include("duc-avatar-frame-user-#{user.id}")
  end

  it "serves private-site CSS to authenticated users without cache storage" do
    item =
      DiscourseUserCosmetics::Item.create!(
        kind: "nameplate",
        name: "Private site plate",
        gradient_from: "#112233",
        gradient_to: "#445566",
      )
    DiscourseUserCosmetics::SelectionService.select!(
      user: user,
      kind: "nameplate",
      item_id: item.id,
    )
    SiteSetting.login_required = true
    sign_in(user)

    get "/user-cosmetics/frames.css"

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/css")
    expect(response.headers["Cache-Control"]).to include("no-store")
    expect(response.headers["Cache-Control"]).not_to include("public")
    expect(response.body).to include("duc-nameplate-post-user-#{user.id}")
    expect(response.body).to include("duc-nameplate-mention-user-#{user.id}")
  end
end
