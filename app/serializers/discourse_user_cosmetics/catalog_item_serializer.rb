# frozen_string_literal: true

module ::DiscourseUserCosmetics
  class CatalogItemSerializer < ApplicationSerializer
    attributes :id,
               :kind,
               :name,
               :description,
               :image_url,
               :gradient_from,
               :gradient_to,
               :glow_color,
               :rarity_label,
               :rarity_color,
               :owned

    def image_url
      if object.kind == "profile_effect"
        DiscourseUserCosmetics::Presenter.effect_fields(object)[:image_url]
      else
        object.resolved_image_url
      end
    end

    def owned
      @options[:owned] == true
    end
  end
end
