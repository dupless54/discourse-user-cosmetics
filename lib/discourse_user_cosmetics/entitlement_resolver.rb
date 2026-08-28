# frozen_string_literal: true

module ::DiscourseUserCosmetics
  class EntitlementResolver
    def self.usable_item_ids(user:, items:)
      return {} unless user

      items = Array(items)
      item_ids = items.map(&:id)
      return {} if item_ids.empty?

      usable =
        if custom_item_access?(items)
          # Backward compatibility for companion plugins that still extend
          # Item#usable_by?. New integrations should use Integration's batch
          # entitlement-provider contract instead.
          canonical_usable_item_ids(user: user, items: items)
        else
          base_usable_item_ids(user: user, items: items, item_ids: item_ids)
        end

      return usable unless defined?(DiscourseUserCosmetics::Integration)

      DiscourseUserCosmetics::Integration.apply_entitlement_providers(
        user: user,
        items: items,
        usable_item_ids: usable,
      )
    end

    def self.base_usable_item_ids(user:, items:, item_ids:)
      restrictions_by_item = Hash.new { |hash, item_id| hash[item_id] = [] }
      DiscourseUserCosmetics::ItemGroup.where(item_id: item_ids).pluck(:item_id, :group_id).each do |item_id, group_id|
        restrictions_by_item[item_id] << group_id
      end

      usable = {}
      restricted_items = []

      items.each do |item|
        group_ids = restrictions_by_item[item.id]
        if item.is_default? || group_ids.empty?
          usable[item.id] = true
        else
          restricted_items << [item.id, group_ids]
        end
      end

      return usable if restricted_items.empty?

      relevant_group_ids = restricted_items.flat_map(&:last).uniq
      member_group_ids =
        ::GroupUser.where(user_id: user.id, group_id: relevant_group_ids).pluck(:group_id).index_with(true)
      unresolved_item_ids = []

      restricted_items.each do |item_id, group_ids|
        if group_ids.any? { |group_id| member_group_ids.key?(group_id) }
          usable[item_id] = true
        else
          unresolved_item_ids << item_id
        end
      end

      if unresolved_item_ids.any?
        DiscourseUserCosmetics::UserItem.where(
          user_id: user.id,
          item_id: unresolved_item_ids,
        ).pluck(:item_id).each { |item_id| usable[item_id] = true }
      end

      usable
    end
    private_class_method :base_usable_item_ids

    def self.custom_item_access?(items)
      items.any? { |item| item.method(:usable_by?).owner != DiscourseUserCosmetics::Item }
    end
    private_class_method :custom_item_access?

    def self.canonical_usable_item_ids(user:, items:)
      items.each_with_object({}) do |item, usable|
        usable[item.id] = true if item.usable_by?(user)
      end
    end
    private_class_method :canonical_usable_item_ids
  end
end
