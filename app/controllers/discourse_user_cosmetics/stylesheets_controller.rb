# frozen_string_literal: true

module ::DiscourseUserCosmetics
  class StylesheetsController < ::ApplicationController
    requires_plugin DiscourseUserCosmetics::PLUGIN_NAME

    skip_before_action :check_xhr, :verify_authenticity_token, :redirect_to_login_if_required,
                        :preload_json, raise: false

    # GET /user-cosmetics/frames.css
    # Publicly cacheable, versioned CSS file with one rule-pair per user who
    # has an active avatar frame. See DiscourseUserCosmetics::CssBuilder.
    def frames
      version = DiscourseUserCosmetics::Presenter.cache_version

      css =
        Discourse
          .cache
          .fetch("discourse_user_cosmetics/frames_css/#{version}", expires_in: 1.hour) do
            DiscourseUserCosmetics::CssBuilder.build_frames_css
          end

      response.headers["Content-Type"] = "text/css; charset=utf-8"
      response.headers["Cache-Control"] = "public, max-age=300"
      render plain: css, content_type: "text/css"
    end
  end
end
