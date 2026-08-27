# frozen_string_literal: true

# name: discourse-user-cosmetics
# about: Discord tarzı kullanıcı kozmetikleri -- avatar çerçeveleri, isim plakaları ve kullanıcı kartı dekorasyonları.
# version: 1.1.3
# authors: dupless54
# url: https://github.com/dupless54/discourse-user-cosmetics
# required_version: 3.1.0

enabled_site_setting :discourse_user_cosmetics_enabled

register_asset "stylesheets/common/discourse-user-cosmetics.scss"

module ::DiscourseUserCosmetics
  PLUGIN_NAME = "discourse-user-cosmetics"
end

after_initialize do
  # --- load our Ruby code -------------------------------------------------
  require_relative "lib/discourse_user_cosmetics/asset_policy"
  require_relative "app/models/discourse_user_cosmetics/item"
  require_relative "app/models/discourse_user_cosmetics/item_group"
  require_relative "app/models/discourse_user_cosmetics/user_item"
  require_relative "app/models/discourse_user_cosmetics/user_selection"
  require_relative "app/models/discourse_user_cosmetics/effect_layer"
  require_relative "lib/discourse_user_cosmetics/presenter"
  require_relative "lib/discourse_user_cosmetics/css_builder"
  require_relative "lib/discourse_user_cosmetics/seeder"
  require_relative "app/controllers/discourse_user_cosmetics/items_controller"
  require_relative "app/controllers/discourse_user_cosmetics/admin_items_controller"
  require_relative "app/controllers/discourse_user_cosmetics/stylesheets_controller"

  # --- admin nav entry (Admin > Plugins > User Cosmetics) -----------------
  add_admin_route "discourse_user_cosmetics.title", "user-cosmetics"

  # --- routes ---------------------------------------------------------------
  Discourse::Application.routes.append do
    # Server-side fallback so a direct browser visit to the admin page
    # renders the normal admin shell (the Ember router takes over from there).
    get "/admin/plugins/user-cosmetics" => "admin/plugins#index", constraints: StaffConstraint.new

    get "/user-cosmetics/mine" => "discourse_user_cosmetics/items#mine", defaults: { format: :json }
    put "/user-cosmetics/select" => "discourse_user_cosmetics/items#select", defaults: { format: :json }
    get "/user-cosmetics/frames.css" => "discourse_user_cosmetics/stylesheets#frames"

    scope "/admin/plugins/user-cosmetics", constraints: StaffConstraint.new do
      defaults format: :json do
        get "/items" => "discourse_user_cosmetics/admin_items#index"
        post "/items" => "discourse_user_cosmetics/admin_items#create"
        put "/items/:id" => "discourse_user_cosmetics/admin_items#update", constraints: { id: /\d+/ }
        delete "/items/:id" => "discourse_user_cosmetics/admin_items#destroy", constraints: { id: /\d+/ }
        post "/items/:id/grant" => "discourse_user_cosmetics/admin_items#grant", constraints: { id: /\d+/ }
        delete "/items/:id/revoke" => "discourse_user_cosmetics/admin_items#revoke", constraints: { id: /\d+/ }
        get "/items/:id/owners" => "discourse_user_cosmetics/admin_items#owners", constraints: { id: /\d+/ }
      end
    end
  end

  # --- expose "what am I wearing" on the serializers the front-end reads ---
  %i[user_card user current_user].each do |serializer_name|
    add_to_serializer(serializer_name, :cosmetics) { ::DiscourseUserCosmetics::Presenter.summary_for(object) }
  end

  # --- starter content so the admin screen isn't empty on first install ----
  DiscourseUserCosmetics::Seeder.seed_defaults!
end
