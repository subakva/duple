require 'ohsnap/version'
require 'thor'
require 'thor/group'
require 'ohsnap/cli/helpers'
require 'ohsnap/cli/refresh'

module Ohsnap
  module CLI
    class Root < Thor
      include Thor::Actions
      include Ohsnap::CLI::Helpers

      register Ohsnap::CLI::Refresh, 'refresh', 'refresh', 'Refreshes a target database from a source database.'
    end
  end
end
