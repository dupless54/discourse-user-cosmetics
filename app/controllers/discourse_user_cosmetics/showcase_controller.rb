# frozen_string_literal: true

module ::DiscourseUserCosmetics
  class ShowcaseController < ::ApplicationController
    requires_plugin DiscourseUserCosmetics::PLUGIN_NAME
    requires_login

    def update
      showcase =
        DiscourseUserCosmetics::Integration.update_showcase!(
          user: current_user,
          item_ids: params[:item_ids],
        )

      render json: { showcase: showcase }
    rescue DiscourseUserCosmetics::ShowcaseService::InvalidShowcase => error
      render json: { errors: [error.message] }, status: :unprocessable_entity
    end
  end
end
