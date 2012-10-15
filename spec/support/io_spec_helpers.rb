module Ohsnap
  module IOSpecHelpers
    def suppress_output
      @original_stdout, $stdout = $stdout, StringIO.new
      @original_stderr, $stderr = $stderr, StringIO.new
    end

    def reset_output
      $stdout = @original_stdout
      $stderr = @original_stderr
    end

    def capture_stdout
      original_stdout, $stdout = $stdout, StringIO.new
      yield
      $stdout.string
    ensure
      $stdout = original_stdout
    end

    def capture_stderr
      original_stderr, $stderr = $stderr, StringIO.new
      yield
      $stderr.string
    ensure
      $stderr = original_stderr
    end
  end
end

RSpec.configure do |config|
  config.include Ohsnap::IOSpecHelpers
end
