module Ohsnap
  module CLI
    class Init < Thor::Group
      include Ohsnap::CLI::Helpers

      def create_sample_config
        config_path = app_config_path(false)
        empty_directory(File.dirname(config_path))
        copy_file('templates/config/ohsnap.yml', config_path)
      end
    end
  end
end
