require 'spec_helper'

describe Ohsnap::CLI::Structure do
  let(:runner) {
    runner = fire_double('Ohsnap::Runner')
    Ohsnap::Runner.stub(:new).and_return(runner)
    runner
  }

  def stub_fetch_config
    runner.stub(:capture).with(/heroku config/)
      .and_return(File.read('spec/config/heroku.txt'))
  end

  def stub_dump_structure
    runner.stub(:run).with(/pg_dump/)
  end

  def stub_reset_db
    # TODO
  end

  def stub_restore_structure
    runner.stub(:run).with(/pg_restore/)
  end

  def invoke_structure(source = nil, target = nil)
    script = Ohsnap::CLI::Root.new
    script.invoke(:structure, [], {
      config: 'spec/config/simple.yml',
      source: source,
      target: target
    })
  end

  context 'from heroku to local' do
    it 'fetches the source credentials'
    it 'dumps the structure from the source'
    it 'resets the local database'
    it 'loads the structure into the local database'
  end

  context 'from heroku to heroku' do
    it 'fetches the source credentials'
    it 'fetches the target credentials'
    it 'dumps the structure from the source'
    it 'resets the target database'
    it 'loads the structure into the target database'
  end

  context 'from local to heroku' do
    it 'fetches the target credentials'
    it 'dumps the structure from the local database'
    it 'resets the target database'
    it 'loads the structure into the target database'
  end
end
