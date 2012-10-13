module Ohsnap
  module CLI
    class Copy < Thor::Group
      include Ohsnap::CLI::Helpers

      source_option
      target_option
      group_option
      capture_option
      tables_option

      def print_something
        puts 'Copy!'
      end
    end
  end
end
