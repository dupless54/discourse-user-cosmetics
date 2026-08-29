# frozen_string_literal: true

module ::DiscourseUserCosmetics
  class Integration
    CONTRACT_VERSION = 1
    CONTRACT_CAPABILITY_METHODS = {
      ownership: %i[owned_item_ids owns?],
      entitlements: %i[
        register_entitlement_provider
        unregister_entitlement_provider
        entitled_item_ids
        entitled?
      ],
      grants: %i[grant! revoke!],
      selections: %i[current_selections_for apply_selections!],
      loadouts: %i[
        loadouts_for
        create_loadout!
        rename_loadout!
        delete_loadout!
        apply_loadout!
      ],
      showcase: %i[showcase_for update_showcase!],
    }.freeze

    class << self
      # Integer version for the shape and semantics of the public manifest.
      # Adding a new optional capability does not require a version bump;
      # incompatible manifest changes do.
      def contract_version
        CONTRACT_VERSION
      end

      # Capabilities are derived from the public methods that are actually
      # loaded. This keeps stacked/optional extensions such as showcase honest
      # during plugin initialization and rolling upgrades.
      def capabilities
        CONTRACT_CAPABILITY_METHODS.each_with_object({}) do |(capability, methods), memo|
          memo[capability] = methods.all? { |method_name| respond_to?(method_name) }
        end
      end

      def supports?(capability)
        capability = capability.to_s.strip.to_sym
        capabilities[capability] == true
      end

      def contract_manifest
        {
          version: contract_version,
          capabilities: capabilities,
        }
      end
    end
  end
end
