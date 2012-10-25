require 'duple/config/task'

module Duple

  # Represents the configuration that will be used to perform the data
  # operations.
  #
  # This class should be the only place in the system that knows about the
  # structure of the config file.
  #
  # This class should not have any knowledge of any particular database
  # system. For example, this class can know about the concept of a "tables",
  # but it should know nothing about flags for PostgreSQL commands.
  class Configuration
    HEROKU  = 'heroku'
    LOCAL   = 'local'
    VALID_TYPES = [HEROKU, LOCAL]

    attr_reader :options, :raw_config

    def initialize(config_hash, options)
      @raw_config = config_hash
      @options = options
    end

    def default_target_name
      env_names_by_flag('default_target', true).first
    end

    def target_name
      options[:target] || default_target_name
    end

    def target_environment
      invalid_target_names = env_names_by_flag('allow_target', false, true)
      if invalid_target_names.include?(target_name)
        raise ArgumentError.new("Invalid target: #{target_name} is not allowed to be a target.")
      end
      environment(target_name)
    end

    def heroku_target?
      heroku?(target_environment)
    end

    def local_target?
      local?(target_environment)
    end

    def default_source_name
      env_names_by_flag('default_source', true).first
    end

    def source_name
      options[:source] || default_source_name
    end

    def source_environment
      environment(source_name)
    end

    def heroku_source?
      heroku?(source_environment)
    end

    def local_source?
      local?(source_environment)
    end

    def heroku?(env)
      env['type'] == Duple::Configuration::HEROKU
    end

    def local?(env)
      env['type'] == Duple::Configuration::LOCAL
    end

    def heroku_name(env)
      env['appname']
    end

    def dry_run?
      options[:dry_run]
    end

    def capture?
      options[:capture]
    end

    def group_name
      options[:group]
    end

    def table_names
      options[:tables] || []
    end

    def filtered_tables?
      included_tables.size > 0 || excluded_tables.size > 0
    end

    # Returns an array of tables to include, based on the group config and the
    # --tables option. An empty array indicates that ALL tables should be
    # included. If the group has the include_all flag, an empty array will be
    # returned.
    def included_tables
      tables = table_names
      if group_name
        g = group(group_name)
        return [] if g['include_all']
        tables += (g['include_tables'] || [])
      end
      tables.uniq.sort
    end

    # Returns an array of tables to exclude, based on the group config and the
    # --tables option. The --tables option takes precedence over the --group
    # option, so if a table is excluded from a group, but specified in the
    # --tables option the table will NOT be excluded.
     def excluded_tables
      tables = []
      if group_name
        g = group(group_name)
        tables += (g['exclude_tables'] || [])
      end
      tables -= table_names
      tables
    end

    def db_config(appname, options = nil)
      options ||= {}
      options = {dry_run: false}.merge(options)

      if options[:dry_run]
        db_config_for_dry_run(appname)
      else
        db_config_for_app(appname)
      end
    end

    def db_config_for_dry_run(appname)
      {
        username: "[#{envname}.USER]",
        password: "[#{envname}.PASS]",
        host:     "[#{envname}.HOST]",
        port:     "[#{envname}.PORT]",
        database: "[#{envname}.DB]"
      }
    end

    def db_config_for_app(appname)
      env = environments[appname]
      if env['database'].nil?
        raise ArgumentError.new('Invalid config: "database" is required for a local environment.')
      end
      {
        username: env['username'] || 'postgres',
        password: env['password'] || '',
        host:     env['host'] || 'localhost',
        port:     env['port'] || '5432',
        database: env['database']
      }
    end

    def environments
      raw_config['environments'] || {}
    end

    def environment(env_name)
      env = environments[env_name]
      raise ArgumentError.new("Invalid environment: #{env_name}") if env.nil?
      env
    end

    def groups
      raw_config['groups'] || {}
    end

    def group(group_name)
      group = groups[group_name]
      raise ArgumentError.new("Invalid group: #{group_name}") if group.nil?
      group
    end

    def pre_refresh_tasks
      @pre_refresh_tasks ||= build_tasks(raw_config['pre_refresh'])
    end

    def post_refresh_tasks
      @post_refresh_tasks ||= build_tasks(raw_config['post_refresh'])
    end

    def other_options
      raw_config.reject { |k,v| %w{environments groups pre_refresh post_refresh}.include?(k) }
    end

    protected

    def build_tasks(task_hash)
      return [] if task_hash.nil?
      task_hash.map do |name, command_list|
        Duple::Config::Task.new(name, command_list)
      end
    end

    def env_names_by_flag(flag_name, flag_value, allow_multiple = false)
      matching_envs = environments.select { |n, c| c[flag_name] == flag_value }
      if matching_envs.size > 1 && !allow_multiple
        raise ArgumentError.new("Only a single environment can be #{flag_name}.")
      end
      matching_envs.keys
    end
  end
end
