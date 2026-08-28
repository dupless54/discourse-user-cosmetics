# frozen_string_literal: true

module ::DiscourseUserCosmetics
  class LoadoutService
    MAX_LOADOUTS_PER_USER = 10

    class << self
      def create_from_current!(user:, name:)
        raise ArgumentError, "user is required" unless user

        user.with_lock do
          if DiscourseUserCosmetics::Loadout.where(user_id: user.id).count >= MAX_LOADOUTS_PER_USER
            raise Discourse::InvalidParameters.new(:loadout_limit)
          end

          selection = DiscourseUserCosmetics::UserSelection.find_by(user_id: user.id)
          attributes =
            DiscourseUserCosmetics::Loadout::SLOT_FIELD_FOR_KIND.values.index_with do |field|
              selection&.public_send(field)
            end

          DiscourseUserCosmetics::Loadout.create!(
            { user_id: user.id, name: name }.merge(attributes),
          )
        end
      end

      def rename!(user:, loadout_id:, name:)
        loadout = find_for_user!(user: user, loadout_id: loadout_id)
        loadout.update!(name: name)
        loadout
      end

      def destroy!(user:, loadout_id:)
        loadout = find_for_user!(user: user, loadout_id: loadout_id)
        loadout.destroy!
        true
      end

      def apply!(user:, loadout_id:)
        loadout = find_for_user!(user: user, loadout_id: loadout_id)
        DiscourseUserCosmetics::SelectionService.replace_all!(
          user: user,
          selections: loadout.selection_item_ids,
        )
        loadout.touch
        loadout
      end

      def find_for_user!(user:, loadout_id:)
        raise ArgumentError, "user is required" unless user

        loadout = DiscourseUserCosmetics::Loadout.find_by(id: loadout_id, user_id: user.id)
        raise Discourse::NotFound unless loadout

        loadout
      end
    end
  end
end
