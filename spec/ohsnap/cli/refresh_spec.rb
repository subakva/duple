require 'spec_helper'

describe Ohsnap::CLI::Refresh do
  include Ohsnap::CLISpecHelpers

  def invoke_refresh(options = nil)
    invoke_cli(:refresh, options)
  end

  before { FileUtils.mkdir_p('tmp/ohsnap') }
  after { FileUtils.rm_rf('tmp/ohsnap') }

  context 'from heroku to heroku' do
    before {
      stub_fetch_url
      stub_fetch_config
      stub_reset_heroku
      stub_restore_url
    }

    let(:source) { 'production' }
    let(:target) { 'stage' }

    it 'fetches the latest snapshot URL for the source' do
      runner.should_receive(:capture).with('heroku pgbackups:url -a ohsnap-production')
        .and_return(heroku_pgbackups_url_response)

      invoke_refresh
    end

    it 'resets the target database' do
      runner.should_receive(:run).with(%{heroku pg:reset -a ohsnap-stage})

      invoke_refresh
    end

    it 'does not reset the source database' do
      runner.should_not_receive(:run).with(/heroku pg:reset -a phsnap-production/)

      invoke_refresh
    end

    it 'restores the target from the snapshot URL' do
      db_url = heroku_pgbackups_url_response.strip
      runner.should_receive(:run).with(%{heroku pgbackups:restore DATABASE #{db_url} -a ohsnap-stage})

      invoke_refresh
    end

    it 'does not capture a new snapshot by default' do
        runner.should_not_receive(:run).with(/heroku pgbackups:capture/)
        invoke_refresh
    end

    context 'with the --capture flag' do
      it 'captures a new snapshot before fetching the URL' do
        runner.should_receive(:run).with('heroku pgbackups:capture -a ohsnap-production')
        invoke_refresh(capture: true)
      end
    end

    context 'with a table list' do
      it 'does not download the snapshot'
      it 'dumps the tables in the list'
      it 'loads the dump file into the target database'
    end
  end

  context 'from heroku to local' do
    before {
      stub_fetch_url
      stub_fetch_config
      stub_fetch_backups
      stub_download_snapshot
      stub_reset_local
      stub_restore_data
    }

    let(:source) { 'stage' }
    let(:target) { 'development' }

    it 'fetches the latest snapshot URL for the source' do
      runner.should_receive(:capture).with('heroku pgbackups:url -a ohsnap-stage')
        .and_return(heroku_pgbackups_url_response)

      invoke_refresh
    end

    it 'resets the local database' do
      runner.should_receive(:run).with(%{bundle exec rake db:drop db:create})

      invoke_refresh
    end

    it 'does not reset the source database' do
      runner.should_not_receive(:run).with(/heroku pg:reset/)

      invoke_refresh
    end

    it 'downloads the snapshot from the snapshot URL' do
      runner.should_receive(:run).with(%{curl -o #{snapshot_path} #{heroku_pgbackups_url_response.strip}})

      invoke_refresh
    end

    it 'does not re-download the snapshot if the timestamp has not changed' do
      FileUtils.touch(snapshot_path)

      runner.should_not_receive(:run).with(/curl/)

      invoke_refresh
    end

    it 'loads the snapshot file into the local database' do
      runner.should_receive(:run)
        .with(%{PGPASSWORD="" pg_restore -e -v --no-acl -O -a -h localhost -U postgres -p 5432 -d ohsnap_development < #{snapshot_path}})

      invoke_refresh
    end

    it 'does not capture a new snapshot by default' do
        runner.should_not_receive(:run).with(/heroku pgbackups:capture/)
        invoke_refresh
    end

    context 'with the --capture flag' do
      it 'captures a new snapshot before fetching the URL' do
        runner.should_receive(:run).with('heroku pgbackups:capture -a ohsnap-stage')
        invoke_refresh(capture: true)
      end
    end

    context 'with a table list' do
      it 'does not download the snapshot'
      it 'dumps the tables in the list'
      it 'loads the dump file into the local database'
    end
  end

  context 'from local to heroku' do
    before {
      stub_fetch_config
      stub_dump_data
      stub_reset_heroku
      stub_restore_data
    }

    let(:source) { 'development' }
    let(:target) { 'stage' }

    it 'dumps the data from the local database' do
      runner.should_receive(:run)
        .with(%{PGPASSWORD="" pg_dump -Fc -a -h localhost -U postgres -p 5432 ohsnap_development > tmp/ohsnap/development-data.dump})

      invoke_refresh
    end

    it 'resets the target database' do
      runner.should_receive(:run).with(%{heroku pg:reset -a ohsnap-stage})

      invoke_refresh
    end

    it 'restores the target from the dump' do
      runner.should_receive(:run)
        .with(%{PGPASSWORD="pg-pass" pg_restore -e -v --no-acl -O -a -h pg-host -U pg-user -p 6022 -d pg-db < tmp/ohsnap/development-data.dump})

      invoke_refresh
    end

    it 'does not capture a new snapshot' do
        runner.should_not_receive(:run).with(/heroku pgbackups:capture/)

        invoke_refresh
    end

    context 'with the --capture flag' do
      it 'does not capture a new snapshot' do
        runner.should_not_receive(:run).with(/heroku pgbackups:capture/)

        invoke_refresh(capture: true)
      end
    end

    context 'with a table list' do
      it 'downloads only the tables in the list' do
        runner.should_receive(:run)
          .with(%{PGPASSWORD="" pg_dump -Fc -a -t categories -h localhost -U postgres -p 5432 ohsnap_development > tmp/ohsnap/development-data.dump})

        invoke_refresh(tables: ['categories'])
      end
    end
  end

  context 'with pre-release tasks' do
    it 'executes the task before starting the refresh'

    it 'executes the tasks in order'
  end

  context 'with post-release tasks' do
    it 'executes the task after finishing the refresh'

    it 'executes the tasks in order'
  end


end
