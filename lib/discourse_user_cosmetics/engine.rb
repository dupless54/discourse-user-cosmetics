# frozen_string_literal: true

module ::DiscourseUserCosmetics
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace DiscourseUserCosmetics
    config.autoload_paths << File.join(config.root, "lib")
  end
end
