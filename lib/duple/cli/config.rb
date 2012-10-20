module Duple
  module CLI

    # Usage:
    #   duple config [COMMAND]
    #
    # Options:
    #   -c, [--config=CONFIG]  # The location of the config file.
    #
    # Manage your configuration.
    #
    # Tasks:
    #   duple config all             # Prints the current configuration.
    #   duple config environments    # Prints the environment configurations.
    #   duple config groups          # Prints the group configurations.
    #   duple config help [COMMAND]  # Describe subcommands or one specific subcommand
    #   duple config other           # Prints other options.
    #   duple config post-refresh    # Prints the post-refresh tasks.
    #   duple config pre-refresh     # Prints the pre-refresh tasks.

    # Options:
    #   -c, [--config=CONFIG]  # The location of the config file.
    class Config < Thor
      include Duple::CLI::Helpers

      config_option

      no_tasks do
        def print_hash(header, values)
          say header
          say '-' * 80
          print_table values, indent: 2
          say
        end

        def print_tasks(header, task_list)
          say header
          say '-' * 80
          task_list.each do |task_name, commands|
            say
            say '  ' + task_name
            print_table commands, indent: 4
          end
          say
        end
      end

      desc 'environments', 'Prints the environment configurations.'
      def environments
        print_hash('Environments', config.environments)
      end

      desc 'groups', 'Prints the group configurations.'
      def groups
        print_hash('Groups', config.groups)
      end

      desc 'pre-refresh', 'Prints the pre-refresh tasks.'
      def pre_refresh
        print_tasks('Pre-Refresh Tasks', config.pre_refresh_tasks)
      end

      desc 'post-refresh', 'Prints the post-refresh tasks.'
      def post_refresh
        print_tasks('Post-Refresh Tasks', config.post_refresh_tasks)
      end

      desc 'other', 'Prints other options.'
      def other
        print_hash('Other Options', config.other_options)
      end

      desc 'all', 'Prints the current configuration.'
      def all
        environments
        groups
        pre_refresh
        post_refresh
        other
      end
    end
  end
end
