module Ohsnap
  module CLI
    class Init < Thor::Group
      include Ohsnap::CLI::Helpers

      def create_sample_config
        empty_directory(File.dirname(app_config_path))
        copy_file('templates/config/ohsnap.yml', app_config_path)
      end
    end
  end
end
