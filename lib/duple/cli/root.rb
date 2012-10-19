require 'thor'
require 'thor/group'
require 'duple/cli/helpers'
require 'duple/cli/init'
require 'duple/cli/copy'
require 'duple/cli/config'
require 'duple/cli/structure'
require 'duple/cli/refresh'
require 'duple/runner'
require 'duple/pg_runner'
require 'duple/heroku_runner'

module Duple
  module CLI
    class Root < Thor
      include Duple::CLI::Helpers

      # HACK Override register to handle class_options for groups properly.
      def self.register(klass, task_name, description)
        super(klass, task_name, task_name, description)
        tasks[task_name].options = klass.class_options
      end

      register Duple::CLI::Init,     'init',
        'Generates a sample configuration file.'

      register Duple::CLI::Copy,     'copy',
        'Copies data from a source to a target database.'

      register Duple::CLI::Structure,     'structure',
        'Copies structure from a source to a target database.'

      register Duple::CLI::Refresh,  'refresh',
        'Resets and copies schema and data from a source to a target database'

      register Duple::CLI::Config,
        'config [COMMAND]', 'Manage your configuration.'
    end
  end
end

