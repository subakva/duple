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

      def fetch_snapshot_url
        @source_snapshot_url = heroku.capture(source_appname, 'pgbackups:url').strip
      end

      def reset_target
        reset_database(config.target_environment)
      end

      def restore_database
        heroku.run(target_appname, "pgbackups:restore DATABASE #{@source_snapshot_url}")
      end
    end
  end
end
