module Ohsnap
  module CLI
    class Refresh < Thor::Group
      include Ohsnap::CLI::Helpers

      config_option
      source_option
      target_option
      group_option
      capture_option
      tables_option

      no_tasks do
        def capture_snapshot?
          config.capture? && config.heroku_source?
        end

        def fetch_snapshot_url?
          config.heroku_source? && !config.filtered_tables?
        end

        def download_snapshot?
          config.heroku_source? && config.local_target? && !config.filtered_tables?
        end

        def dump_data?
          config.local_source? || config.filtered_tables?
        end
      end

      def capture_snapshot
        return unless capture_snapshot?

        heroku.run(source_appname, 'pgbackups:capture')
      end

      def fetch_snapshot_url
        return unless fetch_snapshot_url?

        @source_snapshot_url = heroku.capture(source_appname, 'pgbackups:url').strip
      end

      def download_snapshot
        return unless download_snapshot?

        timestamp = fetch_latest_snapshot_time(source_appname)

        @snapshot_path = snapshot_file_path(timestamp.strftime('%Y-%m-%d-%H-%M-%S'))
        unless File.exists?(@snapshot_path)
          runner.run("curl -o #{@snapshot_path} #{@source_snapshot_url}")
        end
      end

      def dump_data
        return unless dump_data?

        postgres.pg_dump(dump_flags, data_file_path, source_credentials)
      end

      def reset_target
        reset_database(config.target_environment)
      end

      def restore_database
        if download_snapshot?
          postgres.pg_restore('-e -v --no-acl -O -a', @snapshot_path, target_credentials)
        elsif dump_data?
          postgres.pg_restore('-e -v --no-acl -O -a', data_file_path, target_credentials)
        else
          heroku.run(target_appname, "pgbackups:restore DATABASE #{@source_snapshot_url}")
        end
      end
    end
  end
end
