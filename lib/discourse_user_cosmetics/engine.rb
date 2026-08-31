# frozen_string_literal: true

module ::DiscourseUserCosmetics
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace DiscourseUserCosmetics
  end
end
