require 'spec_helper'

describe Ohsnap::CLI::Copy do
  include Ohsnap::CLISpecHelpers

  def invoke_copy(options = nil)
    options ||= {}
    options = { tables: ['categories'] }.merge(options)
    invoke_cli(:copy, options)
  end

  before {
    stub_fetch_config
    stub_dump_data
    stub_restore_data
  }

  context 'with neither tables nor group option' do
    it 'fetches the source credentials' do
      expect {
        invoke_copy(tables: nil)
      }.to raise_error(ArgumentError, 'One of --group or --tables options is required.')
    end
  end

  context 'from heroku to local' do
    let(:source) { 'stage' }
    let(:target) { 'development' }

    it 'fetches the source credentials' do
      runner.should_receive(:capture).with("heroku config -a ohsnap-stage")
        .and_return(heroku_config_response)

      invoke_copy
    end

    it 'dowloads the data from the source' do
      runner.should_receive(:run)
        .with(%{PGPASSWORD="pg-pass" pg_dump -Fc -a -t categories -h pg-host -U pg-user -p 6022 pg-db > tmp/ohsnap/stage-data.dump})

      invoke_copy
    end

    it 'uploads the data to the target' do
      runner.should_receive(:run)
        .with(%{PGPASSWORD="" pg_restore -e -v --no-acl -O -a -h localhost -U postgres -p 5432 -d ohsnap_development < tmp/ohsnap/stage-data.dump})

      invoke_copy
    end
  end

  context 'from heroku to heroku' do
    let(:source) { 'production' }
    let(:target) { 'stage' }

    it 'fetches the source credentials' do
      runner.should_receive(:capture).with("heroku config -a ohsnap-production")
        .and_return(heroku_config_response)

      invoke_copy
    end

    it 'fetches the target credentials' do
      runner.should_receive(:capture).with("heroku config -a ohsnap-stage")
        .and_return(heroku_config_response)

      invoke_copy
    end

    it 'dowloads the data from the source' do
      runner.should_receive(:run)
        .with(%{PGPASSWORD="pg-pass" pg_dump -Fc -a -t categories -h pg-host -U pg-user -p 6022 pg-db > tmp/ohsnap/production-data.dump})

      invoke_copy
    end

    it 'uploads the data to the target' do
      runner.should_receive(:run)
        .with(%{PGPASSWORD="pg-pass" pg_restore -e -v --no-acl -O -a -h pg-host -U pg-user -p 6022 -d pg-db < tmp/ohsnap/production-data.dump})

      invoke_copy
    end
  end

  context 'from local to heroku' do
    let(:source) { 'development' }
    let(:target) { 'stage' }

    it 'fetches the target credentials' do
      runner.should_receive(:capture).with("heroku config -a ohsnap-stage")
        .and_return(heroku_config_response)

      invoke_copy
    end

    it 'dumps the data from the local db' do
      stub_fetch_config
      runner.should_receive(:run)
        .with(%{PGPASSWORD="" pg_dump -Fc -a -t categories -h localhost -U postgres -p 5432 ohsnap_development > tmp/ohsnap/development-data.dump})
      stub_restore_data

      invoke_copy
    end

    it 'uploads the data to the target' do
      runner.should_receive(:run)
        .with(%{PGPASSWORD="pg-pass" pg_restore -e -v --no-acl -O -a -h pg-host -U pg-user -p 6022 -d pg-db < tmp/ohsnap/development-data.dump})

      invoke_copy
    end
  end
end
