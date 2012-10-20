require 'fileutils'

module Duple

  # Helper class for executing shell commands.
  class Runner

    def initialize(options = nil)
      options ||= {}
      @options = {
        log: STDOUT,
        log_format: ' * Running: %s',
        dry_run: false,
        recorder: nil
      }.merge(options)

      if recorder? && !valid_recorder?
        raise ArgumentError.new("Invalid :recorder option: #{@options[:recorder]}")
      end
    end

    def run(command, capture = false)
      log_command(command)
      record_command(command) if recorder?

      return if dry_run?

      result = capture ? `#{command}` : system(command)
      raise RuntimeError.new("Command failed: #{$?}") unless $?.success?
      result
    end

    def capture(command)
      run(command, true)
    end

    def record_command(command)
      @options[:recorder].puts command
    end

    def log_command(command)
      return unless @options[:log]

      formatted = @options[:log_format] % command
      @options[:log].puts formatted
    end

    def valid_recorder?
      @options[:recorder].respond_to?(:puts)
    end

    def recorder?
      @options[:recorder]
    end

    def live?
      !@options[:dry_run]
    end

    def dry_run?
      @options[:dry_run]
    end
  end
end

