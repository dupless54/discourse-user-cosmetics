# frozen_string_literal: true

module ::DiscourseUserCosmetics
  class StylesheetsController < ::ApplicationController
    requires_plugin DiscourseUserCosmetics::PLUGIN_NAME

    skip_before_action :check_xhr, :verify_authenticity_token, :redirect_to_login_if_required,
                        :preload_json, raise: false

    # GET /user-cosmetics/frames.css
    # Publicly cacheable, conditionally revalidated CSS file with one rule-pair
    # per user who has an active avatar frame/nameplate. The cache identity
    # includes catalog/selection changes, group-entitlement changes, and feature
    # gates so stale authorization state is never served after revalidation.
    def frames
      presenter = DiscourseUserCosmetics::Presenter
      state = [presenter.cache_version, presenter.stylesheet_version, presenter.feature_gate_signature].join("/")

      response.headers["Content-Type"] = "text/css; charset=utf-8"
      return unless stale?(
        etag: "discourse-user-cosmetics-frames/#{state}",
        public: true,
        cache_control: { no_cache: true },
      )

      css =
        Discourse
          .cache
          .fetch("discourse_user_cosmetics/frames_css/#{state}", expires_in: 1.hour) do
            DiscourseUserCosmetics::CssBuilder.build_frames_css
          end

      render plain: css, content_type: "text/css"
    end
  end
end
