module Ohsnap
  module CLI
    class Refresh < Thor::Group
      include Ohsnap::CLI::Helpers

      config_option
      source_option
      target_option
      group_option
      capture_option
      tables_option

      def do_something
      end
    end
  end
end
