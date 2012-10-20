module Duple
  module CLI

    # Usage:
    #   duple copy
    #
    # Options:
    #   -c, [--config=CONFIG]         # The location of the config file.
    #   -s, [--source=SOURCE]         # The name of the source environment.
    #   -t, [--target=TARGET]         # The name of the target environment.
    #   -g, [--group=GROUP]           # The group configuration to use when dumping source data.
    #       [--capture]               # Capture a new source snapshot before refreshing.
    #   --dry-run, [--dry-run]        # Perform a dry run of the command. No data will be moved.
    #   -t, [--tables=one two three]  # A list of tables to include when dumping source data.
    #
    # Copies data from a source to a target database.
    class Copy < Thor::Group
      include Duple::CLI::Helpers

      config_option
      source_option
      target_option
      group_option
      capture_option
      dry_run_option
      tables_option

      def require_included_tables
        unless config.included_tables.size > 0
          raise ArgumentError.new('One of --group or --tables options is required.')
        end
      end

      def dump_data
        postgres.pg_dump(dump_flags, data_file_path, source_credentials)
      end

      def restore_data
        postgres.pg_restore('-e -v --no-acl -O -a', data_file_path, target_credentials)
      end
    end
  end
end
