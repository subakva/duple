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
  end

  module PostgreSQLEndpoint
    def db_config
      config.db_config(name)
    end
  end
end
