require 'spec_helper'

describe Ohsnap::CLI::Init do
  before { FileUtils.mkdir_p('tmp/ohsnap/init') }
  after { FileUtils.rm_rf('tmp/ohsnap') }

  it 'creates a config file in the default location' do
    FileUtils.chdir('tmp/ohsnap/init') do
      script = Ohsnap::CLI::Root.new
      script.invoke(:init)

      Pathname.new("config/ohsnap.yml").should exist
    end
  end
end
