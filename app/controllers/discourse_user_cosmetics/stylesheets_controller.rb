# frozen_string_literal: true

module ::DiscourseUserCosmetics
  class StylesheetsController < ::ApplicationController
    requires_plugin DiscourseUserCosmetics::PLUGIN_NAME

    skip_before_action :check_xhr, :verify_authenticity_token, :preload_json, raise: false

    # GET /user-cosmetics/frames.css
    # Public sites use a shared, conditionally revalidated stylesheet. On
    # login-required sites the normal Discourse login guard remains active and
    # authenticated responses are never stored by browser/shared caches.
    def frames
      presenter = DiscourseUserCosmetics::Presenter
      state = [presenter.cache_version, presenter.stylesheet_version, presenter.feature_gate_signature].join("/")

      response.headers["Content-Type"] = "text/css; charset=utf-8"

      if SiteSetting.login_required
        no_store
        render plain: cached_stylesheet(state), content_type: "text/css"
        return
      end

      return unless stale?(
        etag: "discourse-user-cosmetics-frames/#{state}",
        public: true,
        cache_control: { no_cache: true },
      )

      render plain: cached_stylesheet(state), content_type: "text/css"
    end

    private

    def cached_stylesheet(state)
      Discourse.cache.fetch("discourse_user_cosmetics/frames_css/#{state}", expires_in: 1.hour) do
        DiscourseUserCosmetics::CssBuilder.build_frames_css
      end
    end
  end
end
