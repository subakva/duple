module Duple
  module CLI

    # Usage:
    #   duple refresh
    #
    # Options:
    #   -c, [--config=CONFIG]         # The location of the config file.
    #   -s, [--source=SOURCE]         # The name of the source environment.
    #   -t, [--target=TARGET]         # The name of the target environment.
    #   -g, [--group=GROUP]           # The group configuration to use when dumping source data.
    #       [--capture]               # Capture a new source snapshot before refreshing.
    #   -t, [--tables=one two three]  # A list of tables to include when dumping source data.
    #
    # Resets and copies schema and data from a source to a target database
    class Refresh < Thor::Group
      include Duple::CLI::Helpers

      config_option
      source_option
      target_option
      group_option
      capture_option
      tables_option

      no_tasks do
        def fetch_snapshot_url?
          config.heroku_source? && !config.filtered_tables?
        end

        def download_snapshot?
          config.heroku_source? && config.local_target? && !config.filtered_tables?
        end

        def dump_data?
          config.local_source? || config.filtered_tables?
        end

        def run_tasks(tasks)
          tasks.each do |task|
            task.commands.each do |c|
              source.execute(c) if c.source?
              target.execute(c) if c.target?
            end
          end
        end
      end

      def run_prerefresh_tasks
        run_tasks(config.pre_refresh_tasks)
      end

      def capture_snapshot
        source.capture_snapshot if config.capture?
      end

      def fetch_snapshot_url
        return unless fetch_snapshot_url?

        @source_snapshot_url = source.snapshot_url
      end

      def download_snapshot
        return unless download_snapshot?

        timestamp = source.latest_snapshot_time

        @snapshot_path = snapshot_file_path(timestamp.strftime('%Y-%m-%d-%H-%M-%S'))
        unless File.exists?(@snapshot_path)
          runner.run("curl -o #{@snapshot_path} #{@source_snapshot_url}")
        end
      end

      def dump_data
        return unless dump_data?

        postgres.pg_dump(dump_flags, data_file_path, source_db_config)
      end

      def reset_target
        reset_database(config.target_environment)
      end

      def restore_database
        if download_snapshot?
          postgres.pg_restore('-e -v --no-acl -O -a', @snapshot_path, target_db_config)
        elsif dump_data?
          postgres.pg_restore('-e -v --no-acl -O -a', data_file_path, target_db_config)
        else
          heroku.run(target_appname, "pgbackups:restore DATABASE #{@source_snapshot_url}")
        end
      end

      def run_postrefresh_tasks
        run_tasks(config.post_refresh_tasks)
      end
    end
  end
end
