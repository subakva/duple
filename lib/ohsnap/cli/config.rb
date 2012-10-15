module Ohsnap
  module CLI
    class Config < Thor
      include Ohsnap::CLI::Helpers

      desc 'print', 'Prints the current configuration.'
      def print
        require 'pp'
        pp parse_config
      end
    end
  end
end
