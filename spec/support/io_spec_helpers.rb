module IOSpecHelpers
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

RSpec.configure do |config|
  config.include(IOSpecHelpers)
end
