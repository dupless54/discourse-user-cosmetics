# frozen_string_literal: true

DiscourseUserCosmetics::Engine.routes.draw do
  get "/user-cosmetics/mine" => "items#mine", defaults: { format: :json }
  put "/user-cosmetics/select" => "items#select", defaults: { format: :json }
  put "/user-cosmetics/showcase" => "showcase#update", defaults: { format: :json }
  get "/user-cosmetics/frames.css" => "stylesheets#frames"

  scope "/admin/plugins/user-cosmetics", constraints: StaffConstraint.new do
    defaults format: :json do
      get "/items" => "admin_items#index"
      post "/items" => "admin_items#create"
      put "/items/:id" => "admin_items#update", constraints: { id: /\d+/ }
      delete "/items/:id" => "admin_items#destroy", constraints: { id: /\d+/ }
      post "/items/:id/grant" => "admin_items#grant", constraints: { id: /\d+/ }
      delete "/items/:id/revoke" => "admin_items#revoke", constraints: { id: /\d+/ }
      get "/items/:id/owners" => "admin_items#owners", constraints: { id: /\d+/ }
    end
  end
end

Discourse::Application.routes.draw do
  get "/admin/plugins/user-cosmetics" => "admin/plugins#index", constraints: StaffConstraint.new

  %w[u users].each do |root_path|
    get "/#{root_path}/:username/preferences/cosmetics" => "users#preferences",
        constraints: { username: RouteFormat.username }
  end

  mount ::DiscourseUserCosmetics::Engine, at: "/"
end
