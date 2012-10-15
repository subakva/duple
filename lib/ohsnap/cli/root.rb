require 'thor'
require 'thor/group'
require 'ohsnap/cli/helpers'
require 'ohsnap/cli/init'
require 'ohsnap/cli/copy'
require 'ohsnap/cli/config'
require 'ohsnap/cli/structure'
require 'ohsnap/cli/refresh'
require 'ohsnap/runner'
require 'ohsnap/pg_runner'
require 'ohsnap/heroku_runner'

module Ohsnap
  module CLI
    class Root < Thor
      include Ohsnap::CLI::Helpers

      config_option

      # HACK Override register to handle class_options for groups properly.
      def self.register(klass, task_name, description)
        super(klass, task_name, task_name, description)
        tasks[task_name].options = klass.class_options
      end

      register Ohsnap::CLI::Init,     'init',
        'Generates a sample configuration file.'

      register Ohsnap::CLI::Copy,     'copy',
        'Copies data from a source to a target database.'

      register Ohsnap::CLI::Structure,     'structure',
        'Copies structure from a source to a target database.'

      register Ohsnap::CLI::Refresh,  'refresh',
        'Resets and copies schema and data from a source to a target database'

      register Ohsnap::CLI::Config,
        'config [COMMAND]', 'Manage your configuration.'
    end
  end
end

