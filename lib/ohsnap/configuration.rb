module Ohsnap
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

    def default_source_name
      env_names_by_flag('default_source', true).first
    end

    def source_name
      options[:source] || default_source_name
    end

    def source_environment
      environment(source_name)
    end

    def heroku?(env)
      env['type'] == Ohsnap::Configuration::HEROKU
    end

    def heroku_name(env)
      env['appname']
    end

    def local?(env)
      env['type'] == Ohsnap::Configuration::LOCAL
    end

    def dry_run?
      options[:dry_run]
    end

    def dry_run_credentials(envname)
      {
        user:     "[#{envname}.USER]",
        password: "[#{envname}.PASS]",
        host:     "[#{envname}.HOST]",
        port:     "[#{envname}.PORT]",
        db:       "[#{envname}.DB]"
      }
    end

    def local_credentials
      # TODO: Override these defaults from the config
      {
        user:     'postgres',
        password: '',
        host:     'localhost',
        port:     '5432',
        db:       'ohsnap_development'
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
      raw_config['pre_refresh'] || {}
    end

    def pre_refresh_task(task_name)
      task = pre_refresh_tasks[task_name]
      raise ArgumentError.new("Invalid pre_refresh task: #{task_name}") if task.nil?
      task
    end

    def post_refresh_tasks
      raw_config['post_refresh'] || {}
    end

    def post_refresh_task(task_name)
      task = post_refresh_tasks[task_name]
      raise ArgumentError.new("Invalid post_refresh task: #{task_name}") if task.nil?
      task
    end

    def other_options
      raw_config.reject { |k,v| %w{environments groups pre_refresh post_refresh}.include?(k) }
    end

    protected

    def env_names_by_flag(flag_name, flag_value, allow_multiple = false)
      matching_envs = environments.select { |n, c| c[flag_name] == flag_value }
      if matching_envs.size > 1 && !allow_multiple
        raise ArgumentError.new("Only a single environment can be #{flag_name}.")
      end
      matching_envs.keys
    end
  end
end
