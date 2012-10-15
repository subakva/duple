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

      def require_either_tables_or_group
        unless options[:group] || options[:tables]
          raise ArgumentError.new("Either --group or --tables options must be provided.")
        end
      end

      def dump_data
        include_tables = options[:tables]
        include_flags = include_tables.map { |t| "-t #{t}" }.join(' ')
        flags = "-Fc -a #{include_flags}"

        postgres.pg_dump(flags, dump_file_path, source_credentials)
      end

      def restore_data
        postgres.pg_restore('-e -v --no-acl -O -a', dump_file_path, target_credentials)
      end
    end
  end
end
