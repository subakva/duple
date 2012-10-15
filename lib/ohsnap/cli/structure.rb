module Ohsnap
  module CLI
    class Structure < Thor::Group
      include Ohsnap::CLI::Helpers

      config_option
      source_option
      target_option

      def do_something
        runner.run('echo "Structure!"')
      end
    end
  end
end
