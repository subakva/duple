module Ohsnap
  module CLI
    class Refresh < Thor::Group
      include Thor::Actions
      include Ohsnap::CLI::Helpers

      def self.source_root
        File.expand_path(File.join(File.dirname(__FILE__), '../../..'))
      end

      def print_something
        puts 'Something.'
      end
    end
  end
end
