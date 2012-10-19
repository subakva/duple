require 'spec_helper'

describe Duple::CLI::Init do
  before  { suppress_output }
  after   { reset_output }

  before { FileUtils.mkdir_p('tmp/duple/init') }
  after { FileUtils.rm_rf('tmp/duple') }

  it 'creates a config file in the default location' do
    FileUtils.chdir('tmp/duple/init') do
      # capture_stdout do
        script = Duple::CLI::Root.new
        script.invoke(:init)
        Pathname.new("config/duple.yml").should exist
      # end
    end
  end
end
