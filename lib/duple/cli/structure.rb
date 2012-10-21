module Duple
  module CLI

    # Usage:
    #   duple structure
    #
    # Options:
    #   -c, [--config=CONFIG]  # The location of the config file.
    #   -s, [--source=SOURCE]  # The name of the source environment.
    #   -t, [--target=TARGET]  # The name of the target environment.
    #
    # Copies structure from a source to a target database.
    class Structure < Thor::Group
      include Duple::CLI::Helpers

      config_option
      source_option
      target_option

      def dump_structure
        postgres.pg_dump('-Fc --no-acl -O -s', structure_file_path, source_db_config)
      end

      def reset_target
        reset_database(config.target_environment)
      end

      def load_structure
        postgres.pg_restore('-v --no-acl -O -s', structure_file_path, target_db_config)
      end
    end
  end
end
