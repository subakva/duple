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

        def app_config_path(verify_file = true)
          config_path = options[:config] || default_config_path
          if verify_file && !File.exists?(config_path)
            raise ArgumentError.new("Missing config file: #{config_path}")
          end
          config_path
        end

        def default_config_path
          File.join('config', 'duple.yml')
        end

        def source
          @source ||= Duple::Source.new(config, runner)
        end

        def target
          @target ||= Duple::Target.new(config, runner)
        end

        def runner
          @runner ||= Duple::Runner.new(dry_run: config.dry_run?)
        end

        def postgres
          # TODO: This should go away as the methods are moved into the endpoint classes.
          @pg_runner ||= Duple::PGRunner.new(runner)
        end

        def heroku
          # TODO: This should go away as the methods are moved into the endpoint classes.
          @heroku ||= Duple::HerokuRunner.new(runner)
        end

        def target_appname
          # TODO: This should go away as the methods are moved into the endpoint classes.
          target.appname
        end

        def dump_dir_path
          # TODO: This should go on the configuration and be configurable.
          File.join('tmp', 'duple')
        end

        def data_file_path
          # TODO: This should go on the configuration and be configurable.
          @data_file_path ||= File.join(dump_dir_path, "#{config.source_name}-data.dump")
        end

        def structure_file_path
          # TODO: This should go on the configuration and be configurable.
          filename = "#{config.source_name}-structure.dump"
          @structure_file_path ||= File.join(dump_dir_path, filename)
        end

        def snapshot_file_path(timestamp)
          # TODO: This should go on the configuration and be configurable.
          filename = "#{config.source_name}-#{timestamp}.dump"
          @structure_file_path ||= File.join(dump_dir_path, filename)
        end

        def source_db_config
          # TODO: This should go away as the methods are moved into the endpoint classes.
          @source_db_config ||= source.db_config
        end

        def target_db_config
          # TODO: This should go away as the methods are moved into the endpoint classes.
          @target_db_config ||= target.db_config
        end

        def reset_database(env)
          # TODO: This should be moved to the endpoint classes.
          if config.heroku?(env)
            appname = config.heroku_name(env)
            heroku.run(appname, 'pg:reset')
          else
            # if yes?("Are you sure you want to reset the #{config.target_name} database?", :red)
            runner.run('bundle exec rake db:drop db:create')
          end
        end

        def dump_flags
          # TODO: This should be moved to the endpoint classes.
          include_tables = config.included_tables
          include_flags = include_tables.map { |t| "-t #{t}" }

          exclude_tables = config.excluded_tables
          exclude_flags = exclude_tables.map { |t| "-T #{t}" }

          flags = [ '-Fc -a', include_flags, exclude_flags ].flatten.compact.join(' ')
        end
      end
    end
  end
end
