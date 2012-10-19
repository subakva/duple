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

      def capture_snapshot
        return unless config.capture? && config.heroku_source?

        heroku.run(source_appname, 'pgbackups:capture')
      end

      def fetch_snapshot_url
        return if config.local_source?

        @source_snapshot_url = heroku.capture(source_appname, 'pgbackups:url').strip
      end

      def download_snapshot
        return if config.local_source? || config.heroku_target?

        timestamp = fetch_latest_snapshot_time(source_appname)

        @snapshot_path = snapshot_file_path(timestamp.strftime('%Y-%m-%d-%H-%M-%S'))
        unless File.exists?(@snapshot_path)
          runner.run("curl -o #{@snapshot_path} #{@source_snapshot_url}")
        end
      end

      def dump_data
        return if config.heroku_source?

        postgres.pg_dump(dump_flags, data_file_path, source_credentials)
      end

      def reset_target
        reset_database(config.target_environment)
      end

      def restore_database
        if config.heroku_target? && config.heroku_source?
          heroku.run(target_appname, "pgbackups:restore DATABASE #{@source_snapshot_url}")
        elsif config.heroku_source?
          postgres.pg_restore('-e -v --no-acl -O -a', @snapshot_path, target_credentials)
        else
          postgres.pg_restore('-e -v --no-acl -O -a', data_file_path, target_credentials)
        end
      end
    end
  end
end
