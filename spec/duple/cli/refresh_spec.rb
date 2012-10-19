require 'spec_helper'

describe Duple::CLI::Refresh do
  include Duple::CLISpecHelpers

  def invoke_refresh(options = nil)
    invoke_cli(:refresh, options)
  end

  before { FileUtils.mkdir_p('tmp/duple') }
  after { FileUtils.rm_rf('tmp/duple') }

  context 'from heroku to heroku' do
    before {
      stub_fetch_url
      stub_reset_heroku
      stub_restore_url
    }

    let(:source) { 'production' }
    let(:target) { 'stage' }

    it 'runs commands in the correct order' do
      runner.should_receive(:run).once.ordered.with(/heroku pgbackups:capture/)
      runner.should_receive(:capture).once.ordered.with(/heroku pgbackups:url/).and_return(heroku_pgbackups_url_response)
      runner.should_receive(:run).once.ordered.with(/heroku pg:reset/)
      runner.should_receive(:run).once.ordered.with(/heroku pgbackups:restore/)

      invoke_refresh(capture: true)
    end

    it 'fetches the latest snapshot URL for the source' do
      runner.should_receive(:capture).with('heroku pgbackups:url -a duple-production')
        .and_return(heroku_pgbackups_url_response)

      invoke_refresh
    end

    it 'resets the target database' do
      runner.should_receive(:run).with(%{heroku pg:reset -a duple-stage})

      invoke_refresh
    end

    it 'does not reset the source database' do
      runner.should_not_receive(:run).with(/heroku pg:reset -a phsnap-production/)

      invoke_refresh
    end

    it 'restores the target from the snapshot URL' do
      db_url = heroku_pgbackups_url_response.strip
      runner.should_receive(:run).with(%{heroku pgbackups:restore DATABASE #{db_url} -a duple-stage})

      invoke_refresh
    end

    it 'does not capture a new snapshot by default' do
        runner.should_not_receive(:run).with(/heroku pgbackups:capture/)
        invoke_refresh
    end

    context 'with the --capture flag' do
      it 'captures a new snapshot before fetching the URL' do
        runner.should_receive(:run).with('heroku pgbackups:capture -a duple-production')
        invoke_refresh(capture: true)
      end
    end

    context 'with a table list' do
      before {
        stub_fetch_config
        stub_dump_data
        stub_restore_data
      }

      it 'runs commands in the correct order' do
        runner.should_not_receive(:capture).with(/heroku pgbackups:url/)
        runner.should_not_receive(:run).with(/heroku pgbackups:restore/)

        runner.should_receive(:run).once.ordered.with(/heroku pgbackups:capture/)
        runner.should_receive(:capture).once.ordered.with(/heroku config -a duple-production/).and_return(heroku_config_response)
        runner.should_receive(:run).once.ordered.with(/pg_dump/).and_return(heroku_config_response)
        runner.should_receive(:run).once.ordered.with(/heroku pg:reset/)
        runner.should_receive(:capture).once.ordered.with(/heroku config -a duple-stage/).and_return(heroku_config_response)
        runner.should_receive(:run).once.ordered.with(/pg_restore/)

        invoke_refresh(capture: true, tables: ['categories'])
      end

      it 'does not download the snapshot' do
        runner.should_not_receive(:capture).with(/pgbackups/)
        runner.should_not_receive(:capture).with(/curl/)

        invoke_refresh(tables: ['categories'])
      end

      it 'dumps the tables in the list' do
        runner.should_receive(:run)
          .with(%{PGPASSWORD="pg-pass" pg_dump -Fc -a -t categories -h pg-host -U pg-user -p 6022 pg-db > tmp/duple/production-data.dump})

        invoke_refresh(tables: ['categories'])
      end

      it 'loads the dump file into the target database' do
        runner.should_receive(:run)
          .with(%{PGPASSWORD="pg-pass" pg_restore -e -v --no-acl -O -a -h pg-host -U pg-user -p 6022 -d pg-db < tmp/duple/production-data.dump})

        invoke_refresh(tables: ['categories'])
      end
    end
  end

  context 'from heroku to local' do
    before {
      stub_fetch_url
      stub_fetch_backups
      stub_download_snapshot
      stub_reset_local
      stub_restore_data
    }

    let(:source) { 'stage' }
    let(:target) { 'development' }

    it 'runs commands in the correct order' do
      runner.should_receive(:run).once.ordered.with(/heroku pgbackups:capture/)
      runner.should_receive(:capture).once.ordered.with(/heroku pgbackups:url/).and_return(heroku_pgbackups_url_response)
      runner.should_receive(:capture).once.ordered.with(/heroku pgbackups/).and_return(heroku_pgbackups_response)
      runner.should_receive(:run).once.ordered.with(/curl/)
      runner.should_receive(:run).once.ordered.with(/rake db:drop db:create/)
      runner.should_receive(:run).once.ordered.with(/pg_restore/)

      invoke_refresh(capture: true)
    end

    it 'fetches the latest snapshot URL for the source' do
      runner.should_receive(:capture).with('heroku pgbackups:url -a duple-stage')
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
        .with(%{PGPASSWORD="" pg_restore -e -v --no-acl -O -a -h localhost -U postgres -p 5432 -d duple_development < #{snapshot_path}})

      invoke_refresh
    end

    it 'does not capture a new snapshot by default' do
        runner.should_not_receive(:run).with(/heroku pgbackups:capture/)
        invoke_refresh
    end

    context 'with the --capture flag' do
      it 'captures a new snapshot before fetching the URL' do
        runner.should_receive(:run).with('heroku pgbackups:capture -a duple-stage')
        invoke_refresh(capture: true)
      end
    end

    context 'with a table list' do
      let(:table_options) { {tables: ['categories']} }

      before {
        stub_fetch_config
        stub_dump_data
        stub_restore_data
      }

      it 'runs commands in the correct order' do
        runner.should_receive(:run).once.ordered.with(/heroku pgbackups:capture/)
        runner.should_receive(:capture).once.ordered.with(/heroku config -a duple-stage/).and_return(heroku_config_response)
        runner.should_receive(:run).once.ordered.with(/pg_dump/)
        runner.should_receive(:run).once.ordered.with(/rake db:drop db:create/)
        runner.should_receive(:run).once.ordered.with(/pg_restore/)

        invoke_refresh(table_options.merge(capture: true))
      end

      it 'does not download the snapshot' do
        runner.should_not_receive(:capture).with(/pgbackups/)
        runner.should_not_receive(:capture).with(/curl/)

        invoke_refresh(table_options)
      end

      it 'dumps the tables in the list' do
        runner.should_receive(:run)
          .with(%{PGPASSWORD="pg-pass" pg_dump -Fc -a -t categories -h pg-host -U pg-user -p 6022 pg-db > tmp/duple/stage-data.dump})

        invoke_refresh(table_options)
      end

      it 'loads the dump file into the target database' do
        runner.should_receive(:run)
          .with(%{PGPASSWORD="" pg_restore -e -v --no-acl -O -a -h localhost -U postgres -p 5432 -d duple_development < tmp/duple/stage-data.dump})

        invoke_refresh(table_options)
      end
    end
  end

  context 'from local to heroku' do
    before {
      stub_dump_data
      stub_reset_heroku
      stub_fetch_config
      stub_restore_data
    }

    let(:source) { 'development' }
    let(:target) { 'stage' }

    it 'runs commands in the correct order' do
      runner.should_receive(:run).once.ordered.with(/pg_dump/)
      runner.should_receive(:run).once.ordered.with(/heroku pg:reset/)
      runner.should_receive(:capture).once.ordered.with(/heroku config -a duple-stage/).and_return(heroku_config_response)
      runner.should_receive(:run).once.ordered.with(/pg_restore/)

      invoke_refresh(capture: true)
    end

    it 'dumps the data from the local database' do
      runner.should_receive(:run)
        .with(%{PGPASSWORD="" pg_dump -Fc -a -h localhost -U postgres -p 5432 duple_development > tmp/duple/development-data.dump})

      invoke_refresh
    end

    it 'resets the target database' do
      runner.should_receive(:run).with(%{heroku pg:reset -a duple-stage})

      invoke_refresh
    end

    it 'restores the target from the dump' do
      runner.should_receive(:run)
        .with(%{PGPASSWORD="pg-pass" pg_restore -e -v --no-acl -O -a -h pg-host -U pg-user -p 6022 -d pg-db < tmp/duple/development-data.dump})

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
          .with(%{PGPASSWORD="" pg_dump -Fc -a -t categories -h localhost -U postgres -p 5432 duple_development > tmp/duple/development-data.dump})

        invoke_refresh(tables: ['categories'])
      end
    end
  end

  context 'with pre-refresh tasks' do
    before { pending 'Implement pre-refresh tasks' }

    before {
      stub_fetch_url
      stub_fetch_config
      stub_fetch_backups
      stub_dump_data
      stub_download_snapshot
      stub_reset_heroku
      stub_reset_local
      stub_restore_url
      stub_restore_data
    }

    let(:source) { 'production' }
    let(:target) { 'stage' }
    let(:task_options) { { config: 'spec/config/tasks.yml' } }

    it 'executes the tasks before refreshing' do
      runner.should_receive(:run).once.ordered.with('heroku maintenance:on -a duple-stage')
      runner.should_receive(:run).any_number_of_times.ordered.with(/heroku pgbackups/)

      invoke_refresh(table_options.merge(capture: true))
    end

    it 'executes the tasks in order' do
      runner.should_receive(:run).once.ordered.with('heroku run "rake refresh:prepare" -a duple-production')
      runner.should_receive(:run).once.ordered.with('heroku maintenance:on -a duple-stage')
      runner.should_receive(:run).once.ordered.with('heroku run "rake refresh:prepare" -a duple-stage')

      invoke_refresh(task_options)
    end

    context 'with a local target' do
      let(:target) { 'development' }

      it 'executes the tasks in order' do
        runner.should_receive(:run).once.ordered.with('heroku run "rake refresh:prepare" -a duple-production')
        runner.should_not_receive(:run).with(/heroku maintenance:on/)
        runner.should_receive(:run).once.ordered.with('rake refresh:prepare')

        invoke_refresh(task_options)
      end
    end

    context 'with a local source' do
      let(:source) { 'development' }

      it 'executes the tasks in order' do
        runner.should_receive(:run).once.ordered.with('rake refresh:prepare')
        runner.should_receive(:run).once.ordered.with('heroku maintenance:on -a duple-stage')
        runner.should_receive(:run).once.ordered.with('heroku run "rake refresh:prepare" -a duple-stage')

        invoke_refresh(task_options)
      end
    end
  end

  context 'with post-refresh tasks' do
    before { pending 'Implement post-refresh tasks' }
    before {
      stub_fetch_url
      stub_fetch_config
      stub_fetch_backups
      stub_dump_data
      stub_download_snapshot
      stub_reset_heroku
      stub_reset_local
      stub_restore_url
      stub_restore_data
    }

    let(:source) { 'production' }
    let(:target) { 'stage' }
    let(:task_options) { { config: 'spec/config/tasks.yml' } }

    it 'executes the tasks after refreshing' do
      runner.should_receive(:run).any_number_of_times.ordered.with(/heroku pgbackups/)
      runner.should_receive(:run).once.ordered.with('heroku maintenance:on -a duple-stage')

      invoke_refresh(table_options.merge(capture: true))
    end

    it 'executes the tasks in order' do
      runner.should_receive(:run).once.ordered.with('heroku run "rake refresh:finish" -a duple-production')
      runner.should_receive(:run).once.ordered.with('heroku maintenance:off -a duple-stage')
      runner.should_receive(:run).once.ordered.with('heroku run "rake refresh:finish" -a duple-stage')

      invoke_refresh(task_options)
    end

    context 'with a local target' do
      let(:target) { 'development' }

      it 'executes the tasks in order' do
        runner.should_receive(:run).once.ordered.with('heroku run "rake refresh:finish" -a duple-production')
        runner.should_not_receive(:run).with(/heroku maintenance:off/)
        runner.should_receive(:run).once.ordered.with('rake refresh:finish')

        invoke_refresh(task_options)
      end
    end

    context 'with a local source' do
      let(:source) { 'development' }

      it 'executes the tasks in order' do
        runner.should_receive(:run).once.ordered.with('rake refresh:finish')
        runner.should_receive(:run).once.ordered.with('heroku maintenance:on -a duple-stage')
        runner.should_receive(:run).once.ordered.with('heroku run "rake refresh:finish" -a duple-stage')

        invoke_refresh(task_options)
      end
    end
  end


end
