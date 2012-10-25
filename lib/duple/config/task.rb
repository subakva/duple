require 'duple/config/command'

module Duple
  module Config
    # Represents a set of commands that can be executed in the source or target environment.
    class Task
      attr_accessor :name, :commands
      def initialize(name, command_list)
        @name = name
        @commands = command_list.map { |c| Duple::Config::Command.new(c) }
      end
    end
  end
end
