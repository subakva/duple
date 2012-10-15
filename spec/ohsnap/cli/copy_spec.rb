require 'spec_helper'

describe Ohsnap::CLI::Copy do
  let(:runner) {
    runner = fire_double('Ohsnap::Runner')
    Ohsnap::Runner.stub(:new).and_return(runner)
    runner
  }

  def stub_fetch_config
    runner.stub(:capture).with(/heroku config/)
      .and_return(File.read('spec/config/heroku.txt'))
  end

  def stub_dump_data
    runner.stub(:run).with(/pg_dump/)
  end

  def stub_restore_data
    runner.stub(:run).with(/pg_restore/)
  end

  def invoke_copy(source = nil, target = nil)
    script = Ohsnap::CLI::Root.new
    script.invoke(:copy, [], {
      config: 'spec/config/simple.yml',
      tables: ['categories'],
      source: source,
      target: target
    })
  end

  context 'from heroku to local' do
    it 'fetches the source credentials' do
      runner.should_receive(:capture)
        .with("heroku config -a ohsnap-stage")
        .and_return(File.read('spec/config/heroku.txt'))
      stub_dump_data
      stub_restore_data

      invoke_copy('stage', 'development')
    end

    it 'dowloads the tables from the source' do
      stub_fetch_config
      runner.should_receive(:run)
        .with(%{PGPASSWORD="pg-pass" pg_dump -Fc -a -t categories -h pg-host -U pg-user -p 6022 pg-db > tmp/ohsnap/stage.dump})
      stub_restore_data

      invoke_copy('stage', 'development')
    end

    it 'uploads the data to the target' do
      stub_fetch_config
      stub_dump_data
      runner.should_receive(:run)
        .with(%{PGPASSWORD="" pg_restore -e -v --no-acl -O -a -h localhost -U postgres -p 5432 -d ohsnap_development < tmp/ohsnap/stage.dump})

      invoke_copy('stage', 'development')
    end
  end

  context 'from heroku to heroku' do
    it 'fetches the target credentials' do
      stub_fetch_config
      runner.should_receive(:capture)
        .with("heroku config -a ohsnap-stage")
        .and_return(File.read('spec/config/heroku.txt'))
      stub_dump_data
      stub_restore_data

      invoke_copy('production', 'stage')
    end

    it 'uploads the data to the target' do
      stub_fetch_config
      stub_dump_data
      runner.should_receive(:run)
        .with(%{PGPASSWORD="pg-pass" pg_restore -e -v --no-acl -O -a -h pg-host -U pg-user -p 6022 -d pg-db < tmp/ohsnap/production.dump})

      invoke_copy('production', 'stage')
    end
  end

  context 'from local to heroku' do
    it 'dumps the data from the local db' do
      stub_fetch_config
      runner.should_receive(:run)
        .with(%{PGPASSWORD="" pg_dump -Fc -a -t categories -h localhost -U postgres -p 5432 ohsnap_development > tmp/ohsnap/development.dump})
      stub_restore_data

      invoke_copy('development', 'stage')
    end
  end

  context 'with a group' do
    it 'downloads only the tables in the group'
  end
end
