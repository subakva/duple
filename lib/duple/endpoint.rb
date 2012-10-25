module Duple
  module Endpoint
    def self.included(base)
      base.send(:attr_reader, :config, :runner)
    end

    def initialize(config, runner)
      @config = config
      @runner = runner
      if config.heroku?(environment)
        extend Duple::HerokuEndpoint
      else
        extend Duple::PostgreSQLEndpoint
      end
    end
  end

  module HerokuEndpoint
    def appname
      @appname ||= config.heroku_name(environment)
    end

    def heroku
      @heroku ||= Duple::HerokuRunner.new(runner)
    end

    def db_config
      @db_config ||= fetch_db_config
    end

    def snapshot_url
      @snapshot_url ||= heroku.capture(appname, 'pgbackups:url').strip
    end

    def latest_snapshot_time
      unless @snapshot_time
        response = heroku.capture(appname, 'pgbackups')
        last_line = response.split("\n").last
        timestring = last_line.match(/\w+\s+(?<timestamp>[\d\s\/\:\.]+)\s+.*/)[:timestamp]
        @snapshot_time = DateTime.strptime(timestring, '%Y/%m/%d %H:%M.%S')
      end
      @snapshot_time
    end

    def fetch_db_config
      # Run the heroku config command first, even if it's a dry run, so
      # that the command to get the config will show up in the dry run log.
      config_vars = heroku.capture(appname, "config")

      if config.dry_run?
        config.db_config(name, dry_run: true)
      else
        parse_config(config_vars)
      end
    end

    def parse_config(config_vars)
      db_url = config_vars.split("\n").detect { |l| l =~ /DATABASE_URL/ }
      raise ArgumentError.new("Missing DATABASE_URL variable for #{appname}") if db_url.nil?

      db_url.match(
        /postgres:\/\/(?<username>.*):(?<password>.*)@(?<host>.*):(?<port>\d*)\/(?<database>.*)/
      )
    end

    def capture_snapshot
      heroku.run(appname, 'pgbackups:capture')
    end

    def execute(cmd)
      if cmd.shell?
        heroku.run(appname, "run \"#{cmd.command}\"")
      elsif cmd.heroku?
        heroku.run(appname, cmd.command)
      end
    end
  end

  module PostgreSQLEndpoint
    def db_config
      config.db_config(name)
    end

    def capture_snapshot
      # Do nothing. When we have non-local PostgreSQL endpoints, this will need to be implemented.
    end

    def execute(cmd)
      runner.run(cmd.command) if cmd.shell?
    end
  end
end
