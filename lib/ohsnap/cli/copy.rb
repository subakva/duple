module Ohsnap
  module CLI
    class Copy < Thor::Group
      include Ohsnap::CLI::Helpers

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
