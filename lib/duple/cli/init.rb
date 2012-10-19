module Duple
  module CLI
    class Init < Thor::Group
      include Duple::CLI::Helpers

      config_option

      def create_sample_config
        config_path = app_config_path(false)
        empty_directory(File.dirname(config_path))
        copy_file('templates/config/duple.yml', config_path)
      end
    end
  end
end
