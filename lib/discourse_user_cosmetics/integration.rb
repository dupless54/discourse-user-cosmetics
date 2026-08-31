# frozen_string_literal: true

module ::DiscourseUserCosmetics
  # Public server-side integration contract for companion plugins.
  #
  # The base plugin remains the authority for direct ownership, active
  # selections, and saved loadouts. Companion plugins may contribute
  # entitlement decisions in batches without patching Item#usable_by?.
  class Integration
    extend IntegrationContract
    extend ShowcaseIntegration

    # Preserve the existing public constants while their implementation lives
    # in Zeitwerk-compatible extension modules.
    CONTRACT_VERSION = IntegrationContract::CONTRACT_VERSION
    CONTRACT_CAPABILITY_METHODS = IntegrationContract::CONTRACT_CAPABILITY_METHODS

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

      def current_selections_for(user:)
        raise ArgumentError, "user is required" unless user

        selection = DiscourseUserCosmetics::UserSelection.find_by(user_id: user.id)
        serialize_current_selections(selection)
      end

      def apply_selections!(user:, selections:)
        raise ArgumentError, "user is required" unless user

        selection =
          DiscourseUserCosmetics::SelectionService.replace_all!(
            user: user,
            selections: selections,
          )

        {
          selections: serialize_current_selections(selection),
          cosmetics: DiscourseUserCosmetics::Presenter.summary_for(user),
        }
      end

      def loadouts_supported?
        true
      end

      def loadouts_for(user:)
        raise ArgumentError, "user is required" unless user

        loadouts =
          DiscourseUserCosmetics::Loadout.where(user_id: user.id).ordered.to_a
        serialize_loadouts(user: user, loadouts: loadouts)
      end

      def create_loadout!(user:, name:)
        loadout =
          DiscourseUserCosmetics::LoadoutService.create_from_current!(
            user: user,
            name: name,
          )
        serialize_loadouts(user: user, loadouts: [loadout]).first
      end

      def rename_loadout!(user:, loadout_id:, name:)
        loadout =
          DiscourseUserCosmetics::LoadoutService.rename!(
            user: user,
            loadout_id: loadout_id,
            name: name,
          )
        serialize_loadouts(user: user, loadouts: [loadout]).first
      end

      def delete_loadout!(user:, loadout_id:)
        DiscourseUserCosmetics::LoadoutService.destroy!(
          user: user,
          loadout_id: loadout_id,
        )
      end

      def apply_loadout!(user:, loadout_id:)
        loadout =
          DiscourseUserCosmetics::LoadoutService.apply!(
            user: user,
            loadout_id: loadout_id,
          )

        {
          loadout: serialize_loadouts(user: user, loadouts: [loadout]).first,
          cosmetics: DiscourseUserCosmetics::Presenter.summary_for(user),
        }
      end

      private

      def serialize_current_selections(selection)
        DiscourseUserCosmetics::UserSelection::FIELD_FOR_KIND.each_with_object({}) do |(kind, field), memo|
          memo[kind] = selection&.public_send(field)
        end
      end

      def serialize_loadouts(user:, loadouts:)
        item_ids =
          loadouts.flat_map { |loadout| loadout.selection_item_ids.values.compact }.uniq
        items =
          if item_ids.empty?
            []
          else
            DiscourseUserCosmetics::Item
              .where(id: item_ids)
              .includes(:image_upload, effect_layers: :image_upload)
              .to_a
          end
        items_by_id = items.index_by(&:id)
        entitlement_candidates =
          items.select do |item|
            item.enabled? && DiscourseUserCosmetics::Item.kind_enabled?(item.kind)
          end
        usable_item_ids =
          DiscourseUserCosmetics::EntitlementResolver.usable_item_ids(
            user: user,
            items: entitlement_candidates,
          )

        loadouts.map do |loadout|
          slots =
            DiscourseUserCosmetics::Loadout::SLOT_FIELD_FOR_KIND.each_with_object({}) do |(kind, field), memo|
              item_id = loadout.public_send(field)
              item = items_by_id[item_id]
              available =
                item_id.blank? ||
                  (item&.enabled? && item.kind == kind &&
                    DiscourseUserCosmetics::Item.kind_enabled?(kind) &&
                    usable_item_ids.key?(item.id))

              memo[kind] = {
                item_id: item_id,
                available: available,
                item: item ? serialize_loadout_item(item) : nil,
              }
            end

          {
            id: loadout.id,
            name: loadout.name,
            updated_at: loadout.updated_at&.iso8601,
            can_apply: slots.values.all? { |slot| slot[:available] },
            slots: slots,
          }
        end
      end

      def serialize_loadout_item(item)
        presentation = DiscourseUserCosmetics::Presenter.serialize_item(item)
        {
          id: item.id,
          kind: item.kind,
          name: item.name,
          image_url: presentation[:image_url],
          gradient_from: presentation[:gradient_from],
          gradient_to: presentation[:gradient_to],
          glow_color: presentation[:glow_color],
          rarity_label: item.rarity_label,
          rarity_color: item.rarity_color,
        }
      end

      def entitlement_providers
        @entitlement_providers ||= {}
      end
    end
  end
end
