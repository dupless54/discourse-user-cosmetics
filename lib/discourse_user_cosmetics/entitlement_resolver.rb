# frozen_string_literal: true

module ::DiscourseUserCosmetics
  class EntitlementResolver
    def self.usable_item_ids(user:, items:)
      return {} unless user

      items = Array(items)
      item_ids = items.map(&:id)
      return {} if item_ids.empty?

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
  end
end
