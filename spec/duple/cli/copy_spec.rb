require 'spec_helper'

describe Duple::CLI::Copy do
  include Duple::CLISpecHelpers

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
    it 'fetches the source db config' do
      expect {
        invoke_copy(tables: nil)
      }.to raise_error(ArgumentError, 'One of --group or --tables options is required.')
    end
  end

  context 'from heroku to local' do
    let(:source) { 'stage' }
    let(:target) { 'development' }

    it 'fetches the source db config' do
      runner.should_receive(:capture).with("heroku config -a duple-stage")
        .and_return(heroku_config_response)

      invoke_copy
    end

    it 'dowloads the data from the source' do
      runner.should_receive(:run)
        .with(%{PGPASSWORD="pg-pass" pg_dump -Fc -a -t categories -h pg-host -U pg-user -p 6022 pg-db > tmp/duple/stage-data.dump})

      invoke_copy
    end

    it 'uploads the data to the target' do
      runner.should_receive(:run)
        .with(%{PGPASSWORD="" pg_restore -e -v --no-acl -O -a -h localhost -U postgres -p 5432 -d duple_development < tmp/duple/stage-data.dump})

      invoke_copy
    end
  end

  context 'from heroku to heroku' do
    let(:source) { 'production' }
    let(:target) { 'stage' }

    it 'fetches the source db config' do
      runner.should_receive(:capture).with("heroku config -a duple-production")
        .and_return(heroku_config_response)

      invoke_copy
    end

    it 'fetches the target db config' do
      runner.should_receive(:capture).with("heroku config -a duple-stage")
        .and_return(heroku_config_response)

      invoke_copy
    end

    it 'dowloads the data from the source' do
      runner.should_receive(:run)
        .with(%{PGPASSWORD="pg-pass" pg_dump -Fc -a -t categories -h pg-host -U pg-user -p 6022 pg-db > tmp/duple/production-data.dump})

      invoke_copy
    end

    it 'uploads the data to the target' do
      runner.should_receive(:run)
        .with(%{PGPASSWORD="pg-pass" pg_restore -e -v --no-acl -O -a -h pg-host -U pg-user -p 6022 -d pg-db < tmp/duple/production-data.dump})

      invoke_copy
    end
  end

  context 'from local to heroku' do
    let(:source) { 'development' }
    let(:target) { 'stage' }

    it 'fetches the target db config' do
      runner.should_receive(:capture).with("heroku config -a duple-stage")
        .and_return(heroku_config_response)

      invoke_copy
    end

    it 'dumps the data from the local db' do
      stub_fetch_config
      runner.should_receive(:run)
        .with(%{PGPASSWORD="" pg_dump -Fc -a -t categories -h localhost -U postgres -p 5432 duple_development > tmp/duple/development-data.dump})
      stub_restore_data

      invoke_copy
    end

    it 'uploads the data to the target' do
      runner.should_receive(:run)
        .with(%{PGPASSWORD="pg-pass" pg_restore -e -v --no-acl -O -a -h pg-host -U pg-user -p 6022 -d pg-db < tmp/duple/development-data.dump})

      invoke_copy
    end
  end
end
