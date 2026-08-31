# frozen_string_literal: true

# name: discourse-user-cosmetics
# about: Discord tarzı kullanıcı kozmetikleri -- avatar çerçeveleri, isim plakaları, kullanıcı kartı dekorasyonları ve profil efektleri.
# version: 1.2.0
# authors: dupless54
# url: https://github.com/dupless54/discourse-user-cosmetics
# required_version: 3.1.0

enabled_site_setting :discourse_user_cosmetics_enabled

register_asset "stylesheets/common/discourse-user-cosmetics.scss"
register_asset "stylesheets/common/discourse-user-cosmetics-profile-native.scss"
register_asset "stylesheets/common/discourse-user-cosmetics-preferences.scss"
register_asset "stylesheets/common/discourse-user-cosmetics-showcase.scss"
register_asset "stylesheets/common/discourse-user-cosmetics-accessibility.scss"
register_asset "stylesheets/common/discourse-user-cosmetics-admin-native.scss"

module ::DiscourseUserCosmetics
  PLUGIN_NAME = "discourse-user-cosmetics"
end

require_relative "lib/discourse_user_cosmetics/engine"

after_initialize do
  # Library files are still loaded explicitly in this phase because the
  # integration contract is split across files that reopen Integration.
  # App models/controllers now load through the isolated Rails engine.
  require_relative "lib/discourse_user_cosmetics/asset_policy"
  require_relative "lib/discourse_user_cosmetics/entitlement_resolver"
  require_relative "lib/discourse_user_cosmetics/presenter"
  require_relative "lib/discourse_user_cosmetics/selection_service"
  require_relative "lib/discourse_user_cosmetics/loadout_service"
  require_relative "lib/discourse_user_cosmetics/showcase_service"
  require_relative "lib/discourse_user_cosmetics/integration"
  require_relative "lib/discourse_user_cosmetics/integration_contract"
  require_relative "lib/discourse_user_cosmetics/showcase_integration"
  require_relative "lib/discourse_user_cosmetics/user_reference_cleanup"
  require_relative "lib/discourse_user_cosmetics/css_builder"
  require_relative "lib/discourse_user_cosmetics/seeder"

  # --- admin nav entry (Admin > Plugins > User Cosmetics) -----------------
  add_admin_route "discourse_user_cosmetics.title", "user-cosmetics"

  on(:user_added_to_group) do |user, group, **_kwargs|
    DiscourseUserCosmetics::Presenter.invalidate_group_membership!(
      user_id: user&.id,
      group_id: group&.id,
    )
  end

  on(:user_removed_from_group) do |user, group|
    DiscourseUserCosmetics::Presenter.invalidate_group_membership!(
      user_id: user&.id,
      group_id: group&.id,
    )
  end

  on(:group_destroyed) do |group, _cached_user_ids|
    removed = DiscourseUserCosmetics::ItemGroup.where(group_id: group&.id).delete_all
    DiscourseUserCosmetics::Presenter.bump_version! if removed.positive?
  end

  on(:user_destroyed) do |user|
    DiscourseUserCosmetics::UserReferenceCleanup.cleanup!(user_id: user&.id)
  end

  on(:user_updated) do |user, changed_fields|
    next if Array(changed_fields).map(&:to_s).exclude?("username")

    DiscourseUserCosmetics::Presenter.invalidate_username_change!(user_id: user&.id)
  end

  %i[user_card user current_user].each do |serializer_name|
    add_to_serializer(serializer_name, :cosmetics) { ::DiscourseUserCosmetics::Presenter.summary_for(object) }
  end

  add_to_serializer(:user, :cosmetics_showcase) do
    ::DiscourseUserCosmetics::ShowcaseService.serialize_for(user: object)
  end

  DiscourseUserCosmetics::Seeder.seed_defaults!
end
