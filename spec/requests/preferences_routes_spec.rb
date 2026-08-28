# frozen_string_literal: true

RSpec.describe "User cosmetics preferences routes", type: :request do
  fab!(:user)

  before do
    enable_current_plugin
    sign_in(user)
  end

  %w[u users].each do |root_path|
    it "serves /#{root_path}/:username/preferences/cosmetics directly" do
      get "/#{root_path}/#{user.username}/preferences/cosmetics"

      expect(response).to be_successful
      expect(response.media_type).to eq("text/html")
    end
  end
end
