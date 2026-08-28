# frozen_string_literal: true

module ::DiscourseUserCosmetics
  class Integration
    class << self
      def showcase_supported?
        true
      end

      def showcase_for(user:)
        raise ArgumentError, "user is required" unless user

        DiscourseUserCosmetics::ShowcaseService.serialize_for(user: user)
      end

      def update_showcase!(user:, item_ids:)
        raise ArgumentError, "user is required" unless user

        DiscourseUserCosmetics::ShowcaseService.replace!(user: user, item_ids: item_ids)
      end
    end
  end
end
