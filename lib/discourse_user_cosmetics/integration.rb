# frozen_string_literal: true

module ::DiscourseUserCosmetics
  # Public server-side integration contract for companion plugins.
  #
  # The base plugin remains the authority for direct ownership and active
  # selections. Companion plugins may contribute entitlement decisions in
  # batches without patching Item#usable_by?.
  class Integration
    class InvalidEntitlementProviderResult < StandardError; end

    class << self
      def register_entitlement_provider(name, &block)
        raise ArgumentError, "provider name is required" if name.blank?
        raise ArgumentError, "provider block is required" unless block

        entitlement_providers[name.to_s] = block
        true
      end

      def unregister_entitlement_provider(name)
        entitlement_providers.delete(name.to_s).present?
      end

      def entitlement_providers?
        entitlement_providers.any?
      end

      # Providers return a hash of item_id => true/false for only the items
      # they intentionally override. Missing ids abstain. Across providers,
      # an explicit denial wins over an allow so one companion cannot bypass
      # another companion's restriction accidentally.
      def apply_entitlement_providers(user:, items:, usable_item_ids:)
        return usable_item_ids unless user && entitlement_providers?

        items = Array(items)
        valid_item_ids = items.map(&:id).compact.to_set
        allowed_item_ids = Set.new
        denied_item_ids = Set.new

        entitlement_providers.each_value do |provider|
          decisions =
            provider.call(
              user: user,
              items: items,
              usable_item_ids: usable_item_ids.dup,
            )
          next if decisions.nil?

          unless decisions.respond_to?(:each_pair)
            raise InvalidEntitlementProviderResult, "entitlement provider must return a hash or nil"
          end

          decisions.each_pair do |raw_item_id, decision|
            item_id = raw_item_id.to_i
            if valid_item_ids.exclude?(item_id) || [true, false].exclude?(decision)
              raise InvalidEntitlementProviderResult,
                    "entitlement provider returned an invalid item or decision"
            end

            decision ? allowed_item_ids.add(item_id) : denied_item_ids.add(item_id)
          end
        end

        result = usable_item_ids.dup
        allowed_item_ids.each { |item_id| result[item_id] = true }
        denied_item_ids.each { |item_id| result.delete(item_id) }
        result
      end

      # Direct ownership only. This intentionally differs from entitlement,
      # which also accounts for defaults, groups, and companion providers.
      def owned_item_ids(user:, items:)
        return {} unless user

        item_ids = Array(items).filter_map(&:id).uniq
        return {} if item_ids.empty?

        DiscourseUserCosmetics::UserItem
          .where(user_id: user.id, item_id: item_ids)
          .pluck(:item_id)
          .index_with(true)
      end

      def owns?(user:, item:)
        return false unless user && item

        owned_item_ids(user: user, items: [item]).key?(item.id)
      end

      def entitled_item_ids(user:, items:)
        return {} unless user

        DiscourseUserCosmetics::EntitlementResolver.usable_item_ids(
          user: user,
          items: Array(items),
        )
      end

      def entitled?(user:, item:)
        return false unless user && item

        entitled_item_ids(user: user, items: [item]).key?(item.id)
      end

      def grant!(user:, item:, granted_by: nil)
        raise ArgumentError, "user and item are required" unless user && item

        was_entitled = entitled?(user: user, item: item)
        user_item =
          DiscourseUserCosmetics::UserItem.find_or_create_by!(
            user_id: user.id,
            item_id: item.id,
          ) do |row|
            row.granted_by_id = granted_by&.id
          end

        if user_item.previously_new_record? && !was_entitled
          DiscourseUserCosmetics::Presenter.invalidate_direct_entitlement_change!(
            user_id: user.id,
            item: item,
          )
        end

        user_item
      end

      def revoke!(user:, item:)
        raise ArgumentError, "user and item are required" unless user && item

        rows = DiscourseUserCosmetics::UserItem.where(user_id: user.id, item_id: item.id).to_a
        rows.each(&:destroy!)
        rows.length
      end

      def equip!(user:, item:)
        raise ArgumentError, "user and item are required" unless user && item

        DiscourseUserCosmetics::SelectionService.select!(
          user: user,
          kind: item.kind,
          item_id: item.id,
        )
      end

      def unequip!(user:, kind:)
        raise ArgumentError, "user is required" unless user

        DiscourseUserCosmetics::SelectionService.select!(user: user, kind: kind, item_id: nil)
      end

      private

      def entitlement_providers
        @entitlement_providers ||= {}
      end
    end
  end
end
