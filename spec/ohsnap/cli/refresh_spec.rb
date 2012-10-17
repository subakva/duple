require 'spec_helper'

describe Ohsnap::CLI::Refresh do
  include Ohsnap::CLISpecHelpers

  def invoke_refresh(options = nil)
    invoke_cli(:refresh, options)
  end

  before {
    stub_fetch_url
    stub_fetch_config
    # stub_dump_structure
    # stub_dump_data
    stub_reset_target
    stub_restore_url
    # stub_restore_structure
    # stub_restore_data
  }

  context 'from heroku to heroku' do
    let(:source) { 'production' }
    let(:target) { 'stage' }

    it 'fetches the latest snapshot URL for the source' do
      runner.should_receive(:capture).with("heroku pgbackups:url -a ohsnap-production")
        .and_return(File.read('spec/config/heroku_pgbackups_url.txt'))

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
      db_url = File.read('spec/config/heroku_pgbackups_url.txt').strip
      runner.should_receive(:run).with(%{heroku pgbackups:restore DATABASE #{db_url} -a ohsnap-stage})

      invoke_refresh
    end

    context 'with the --capture flag' do
      it 'captures a new snapshot before fetching the URL'
    end
  end

  context 'from heroku to local' do
    let(:source) { 'stage' }
    let(:target) { 'development' }

    it 'fetches the latest snapshot URL for the source' do
      runner.should_receive(:capture).with("heroku pgbackups:url -a ohsnap-stage")
        .and_return(File.read('spec/config/heroku_pgbackups_url.txt'))

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

    it 'downloads the dump from the snapshot URL'

    it 'loads the dump file into the local database'

    context 'with the --capture flag' do
      it 'captures a new snapshot before fetching the URL'
    end
  end

  context 'from local to heroku' do
    let(:source) { 'development' }
    let(:target) { 'stage' }

    it 'dumps the data from the local database'

    it 'resets the target database' do
      runner.should_receive(:run).with(%{heroku pg:reset -a ohsnap-stage})

      invoke_refresh
    end

    it 'restores the target from the dump'
  end

  context 'with pre-release tasks' do
    it 'executes the task before starting the refresh'

    it 'executes the tasks in order'
  end

  context 'with post-release tasks' do
    it 'executes the task after finishing the refresh'

    it 'executes the tasks in order'
  end

  context 'with a group' do
    it 'downloads only the tables in the group'
  end

  context 'with a table list' do
    it 'downloads only the tables in the list'
  end
end
