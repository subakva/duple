require 'spec_helper'

describe Ohsnap::CLI::Config do
  it 'prints the configuration' do
    result = capture_stdout do
      script = Ohsnap::CLI::Config.new
      script.invoke(:all, [], {})
    end

    result.should =~ /Environments/
    result.should =~ /Groups/
    result.should =~ /Pre-Refresh Tasks/
    result.should =~ /Post-Refresh Tasks/
    result.should =~ /Other Options/
  end
end
