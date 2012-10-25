module Duple
  module Config
    # Represents a command that can be executed in the source or target environment.
    class Command
      SHELL   = 'shell'
      HEROKU  = 'heroku'
      VALID_TYPES = [SHELL, HEROKU]

      SOURCE = 'source'
      TARGET = 'target'
      VALID_SUBJECTS = [SOURCE, TARGET]

      attr_accessor :subject, :type, :command

      def initialize(config_hash)
        @command = config_hash['command']
        @type = config_hash['command_type']
        @subject = config_hash['subject']

        unless VALID_TYPES.include?(@type)
          raise ArgumentError.new("Invalid config: #{@type} is not a valid command type.")
        end

        unless VALID_SUBJECTS.include?(@subject)
          raise ArgumentError.new("Invalid config: #{@subject} is not a valid command subject.")
        end
      end

      def source?
        subject == Duple::Config::Command::SOURCE
      end

      def target?
        subject == Duple::Config::Command::TARGET
      end

      def heroku?
        type == Duple::Config::Command::HEROKU
      end

      def shell?
        type == Duple::Config::Command::SHELL
      end
    end
  end
end
