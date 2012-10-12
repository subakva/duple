require 'yaml'

module Ohsnap
  module CLI
    module Helpers
      def app_config_path
        File.join('config', 'ohsnap.yml')
      end

      def load_config
        config_path = File.join(destination_root, app_config_path)
        config_data = File.read(config_path)
        YAML.load(config_data) || {}
      end
    end
  end
end
