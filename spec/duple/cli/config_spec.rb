require 'spec_helper'

describe Duple::CLI::Config do
  let(:script) { Duple::CLI::Config.new }
  it 'raises an error if an invalid config path is supplied' do
    expect {
      script.invoke(:all, [], {config: 'spec/config/nonexistent.yml'})
    }.to raise_error(ArgumentError, 'Missing config file: spec/config/nonexistent.yml')
  end

  it 'prints the configuration' do
    result = capture_stdout do
      script.invoke(:all, [], {config: 'spec/config/kitchensink.yml'})
    end

    result.should =~ /Environments/
    result.should =~ /Groups/
    result.should =~ /Pre-Refresh Tasks/
    result.should =~ /Post-Refresh Tasks/
    result.should =~ /Other Options/
  end
end
