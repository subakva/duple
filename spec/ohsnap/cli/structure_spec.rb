require 'spec_helper'

describe Ohsnap::CLI::Structure do
  include Ohsnap::CLISpecHelpers

  def invoke_structure(options = nil)
    invoke_cli(:structure, options)
  end

  context 'from heroku to local' do
    before {
      stub_fetch_config
      stub_dump_structure
      stub_reset_local
      stub_restore_structure
    }

    let(:source) { 'stage' }
    let(:target) { 'development' }

    it 'fetches the source credentials' do
      runner.should_receive(:capture).with("heroku config -a ohsnap-stage")
        .and_return(heroku_config_response)

      invoke_structure
    end

    it 'dumps the structure from the source' do
      runner.should_receive(:run)
        .with(%{PGPASSWORD="pg-pass" pg_dump -Fc --no-acl -O -s -h pg-host -U pg-user -p 6022 pg-db > tmp/ohsnap/stage-structure.dump})

      invoke_structure
    end

    it 'resets the local database' do
      runner.should_receive(:run).with(%{bundle exec rake db:drop db:create})

      invoke_structure
    end

    it 'loads the structure into the local database' do
      runner.should_receive(:run)
        .with(%{PGPASSWORD="" pg_restore -v --no-acl -O -s -h localhost -U postgres -p 5432 -d ohsnap_development < tmp/ohsnap/stage-structure.dump})

      invoke_structure
    end
  end

  context 'from heroku to heroku' do
    before {
      stub_fetch_config
      stub_dump_structure
      stub_reset_heroku
      stub_restore_structure
    }

    let(:source) { 'production' }
    let(:target) { 'stage' }

    it 'fetches the source credentials' do
      runner.should_receive(:capture).with("heroku config -a ohsnap-production")
        .and_return(heroku_config_response)

      invoke_structure
    end

    it 'fetches the target credentials' do
      runner.should_receive(:capture).with("heroku config -a ohsnap-stage")
        .and_return(heroku_config_response)

      invoke_structure
    end

    it 'dumps the structure from the source' do
      runner.should_receive(:run)
        .with(%{PGPASSWORD="pg-pass" pg_dump -Fc --no-acl -O -s -h pg-host -U pg-user -p 6022 pg-db > tmp/ohsnap/production-structure.dump})

      invoke_structure
    end

    it 'resets the target database' do
      runner.should_receive(:run).with(%{heroku pg:reset -a ohsnap-stage})

      invoke_structure
    end

    it 'loads the structure into the target database' do
      runner.should_receive(:run)
        .with(%{PGPASSWORD="pg-pass" pg_restore -v --no-acl -O -s -h pg-host -U pg-user -p 6022 -d pg-db < tmp/ohsnap/production-structure.dump})

      invoke_structure
    end
  end

  context 'from local to heroku' do
    before {
      stub_fetch_config
      stub_dump_structure
      stub_reset_heroku
      stub_restore_structure
    }

    let(:source) { 'development' }
    let(:target) { 'stage' }

    it 'fetches the target credentials' do
      runner.should_receive(:capture).with("heroku config -a ohsnap-stage")
        .and_return(heroku_config_response)

      invoke_structure
    end

    it 'dumps the structure from the local database' do
      runner.should_receive(:run)
        .with(%{PGPASSWORD="" pg_dump -Fc --no-acl -O -s -h localhost -U postgres -p 5432 ohsnap_development > tmp/ohsnap/development-structure.dump})

      invoke_structure
    end

    it 'resets the target database' do
      runner.should_receive(:run).with(%{heroku pg:reset -a ohsnap-stage})

      invoke_structure
    end

    it 'loads the structure into the target database' do
      runner.should_receive(:run)
        .with(%{PGPASSWORD="pg-pass" pg_restore -v --no-acl -O -s -h pg-host -U pg-user -p 6022 -d pg-db < tmp/ohsnap/development-structure.dump})

      invoke_structure
    end
  end
end
