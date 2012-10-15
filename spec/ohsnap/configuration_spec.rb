require 'spec_helper'

describe Ohsnap::Configuration do
  describe '#source_environment' do
    let(:config_hash) { YAML.load(File.read('spec/config/simple.yml'))}

    it 'gets the default source environment' do
      config = Ohsnap::Configuration.new(config_hash, {})
      config.source_environment.should_not be_nil
      config.source_environment['appname'].should == 'ohsnap-stage'
    end

    it 'gets the source environment' do
      config = Ohsnap::Configuration.new(config_hash, { source: 'production' })
      config.source_environment.should_not be_nil
      config.source_environment['appname'].should == 'ohsnap-production'
    end

    it 'does not allow multiple default sources' do
      config_hash['environments']['backstage'] = {'default_source' => true}
      config = Ohsnap::Configuration.new(config_hash, {})
      expect {
        config.source_environment
      }.to raise_error(ArgumentError, 'Only a single environment can be default_source.')
    end
  end

  describe '#target_environment' do
    let(:config_hash) { YAML.load(File.read('spec/config/simple.yml'))}

    it 'gets the default target environment' do
      config = Ohsnap::Configuration.new(config_hash, {})
      config.target_environment.should_not be_nil
      config.target_environment['type'].should == 'local'
    end

    it 'gets the target environment' do
      config = Ohsnap::Configuration.new(config_hash, { target: 'stage' })
      config.target_environment.should_not be_nil
      config.target_environment['appname'].should == 'ohsnap-stage'
    end

    it 'fails if the target is not allowed' do
      config = Ohsnap::Configuration.new(config_hash, { target: 'production' })
      expect {
        config.target_environment
      }.to raise_error(ArgumentError, 'Invalid target: production is not allowed to be a target.')
    end

    it 'does not allow multiple default targets' do
      config_hash['environments']['backstage'] = {'default_target' => true}
      config = Ohsnap::Configuration.new(config_hash, {})
      expect {
        config.target_environment
      }.to raise_error(ArgumentError, 'Only a single environment can be default_target.')
    end

    it 'allows multiple disallowed targets' do
      config_hash['environments']['reporting'] = {'allow_target' => false}
      config = Ohsnap::Configuration.new(config_hash, {})
      expect {
        config.target_environment
      }.to_not raise_error(ArgumentError, 'Only a single environment can be allow_target.')
    end
  end
end
