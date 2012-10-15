module Ohsnap
  module CLI
    class Refresh < Thor::Group
      include Ohsnap::CLI::Helpers

      source_option
      target_option
      group_option
      capture_option
      tables_option

      def do_something
        runner.run('echo "Refresh!"')
      end
    end
  end
end
