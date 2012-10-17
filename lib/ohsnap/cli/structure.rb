module Ohsnap
  module CLI
    class Structure < Thor::Group
      include Ohsnap::CLI::Helpers

      config_option
      source_option
      target_option

      def dump_structure
        postgres.pg_dump('-Fc --no-acl -O -s', structure_file_path, source_credentials)
      end

      def reset_target
        reset_database(config.target_environment)
      end

      def load_structure
        postgres.pg_restore('-v --no-acl -O -s', structure_file_path, target_credentials)
      end
    end
  end
end
