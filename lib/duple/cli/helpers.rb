require 'yaml'

module Duple
  module CLI
    module Helpers

      def self.included(base)
        base.send(:include, Thor::Actions)
        base.send(:include, InstanceMethods)
        base.send(:extend, ClassMethods)
      end

      module ClassMethods
        def source_root
          File.expand_path(File.join(File.dirname(__FILE__), '../../..'))
        end

        def config_option
          class_option :config,
            desc: 'The location of the config file.',
            type: :string,
            aliases: '-c'
        end

        def source_option
          class_option :source,
            desc: 'The name of the source environment.',
            type: :string,
            aliases: '-s'
        end

        def target_option
          class_option :target,
            desc: 'The name of the target environment.',
            type: :string,
            aliases: '-t'
        end

        def group_option
          class_option :group,
            desc: 'The group configuration to use when dumping source data.',
            type: :string,
            aliases: '-g'
        end

        def capture_option
          class_option :capture,
            desc: 'Capture a new source snapshot before refreshing.',
            type: :boolean
        end

        def dry_run_option
          class_option :dry_run,
            desc: 'Perform a dry run of the command. No data will be moved.',
            type: :boolean,
            aliases: '--dry-run'
        end

        def tables_option(opts = nil)
          opts ||= {}
          opts = {
            desc:     'A list of tables to include when dumping source data.',
            required: false,
            type:     :array,
            aliases:  '-t'
          }.merge(opts)
          class_option :tables, opts
        end
      end

      module InstanceMethods
        def default_config_path
          File.join('config', 'duple.yml')
        end

        def app_config_path(verify_file = true)
          config_path = options[:config] || default_config_path
          if verify_file && !File.exists?(config_path)
            raise ArgumentError.new("Missing config file: #{config_path}")
          end
          config_path
        end

        def runner
          @runner ||= Duple::Runner.new(dry_run: config.dry_run?)
        end

        def postgres
          @pg_runner ||= Duple::PGRunner.new(runner)
        end

        def heroku
          @heroku ||= Duple::HerokuRunner.new(runner)
        end

        def source_appname
          @source_appname ||= config.heroku_name(config.source_environment)
        end

        def target_appname
          @target_appname ||= config.heroku_name(config.target_environment)
        end

        def dump_dir_path
          File.join('tmp', 'duple')
        end

        def data_file_path
          @data_file_path ||= File.join(dump_dir_path, "#{config.source_name}-data.dump")
        end

        def structure_file_path
          filename = "#{config.source_name}-structure.dump"
          @structure_file_path ||= File.join(dump_dir_path, filename)
        end

        def snapshot_file_path(timestamp)
          filename = "#{config.source_name}-#{timestamp}.dump"
          @structure_file_path ||= File.join(dump_dir_path, filename)
        end

        def source_db_config
          @source_db_config ||= if config.heroku_source?
                                  fetch_heroku_db_config(source_appname)
                                else
                                  config.db_config(config.source_name)
                                end
        end

        def target_db_config
          @target_db_config ||= if config.heroku_target?
                                  fetch_heroku_db_config(target_appname)
                                else
                                  config.db_config(config.target_name)
                                end
        end

        def fetch_heroku_db_config(appname)
          # Run the heroku config command first, even if it's a dry run. So
          # that the command to get the config will show up in the dry run log.
          config_vars = heroku.capture(appname, "config")

          if config.dry_run?
            config.db_config(appname, dry_run: true)
          else
            parse_heroku_config(config_vars)
          end
        end

        def parse_heroku_config(config_vars)
          db_url = config_vars.split("\n").detect { |l| l =~ /DATABASE_URL/ }
          raise ArgumentError.new("Missing DATABASE_URL variable for #{appname}") if db_url.nil?

          db_url.match(
            /postgres:\/\/(?<username>.*):(?<password>.*)@(?<host>.*):(?<port>\d*)\/(?<database>.*)/
          )
        end

        def fetch_latest_snapshot_time(appname)
          response = heroku.capture(appname, 'pgbackups')
          last_line = response.split("\n").last
          timestring = last_line.match(/\w+\s+(?<timestamp>[\d\s\/\:\.]+)\s+.*/)[:timestamp]
          DateTime.strptime(timestring, '%Y/%m/%d %H:%M.%S')
        end

        def reset_database(env)
          if config.heroku?(env)
            appname = config.heroku_name(env)
            heroku.run(appname, 'pg:reset')
          else
            # if yes?("Are you sure you want to reset the #{config.target_name} database?", :red)
            runner.run('bundle exec rake db:drop db:create')
          end
        end

        def dump_flags
          include_tables = config.included_tables
          include_flags = include_tables.map { |t| "-t #{t}" }

          exclude_tables = config.excluded_tables
          exclude_flags = exclude_tables.map { |t| "-T #{t}" }

          flags = [ '-Fc -a', include_flags, exclude_flags ].flatten.compact.join(' ')
        end

        def config
          @config ||= parse_config
        end

        def parse_config
          config_path = File.join(destination_root, app_config_path)
          config_data = File.read(config_path)
          erbed = ERB.new(config_data).result
          config_hash = YAML.load(erbed) || {}
          Duple::Configuration.new(config_hash, options)
        end
      end
    end
  end
end
