module Ohsnap::CLISpecHelpers
  def self.included(base)
    base.send(:let, :runner) { double_runner }
    base.send(:let, :source) { 'stage' }
    base.send(:let, :target) { 'development' }
  end

  def double_runner
    runner = fire_double('Ohsnap::Runner')
    Ohsnap::Runner.stub(:new).and_return(runner)
    runner
  end

  def stub_fetch_config
    runner.stub(:capture).with(/heroku config/)
      .and_return(File.read('spec/config/heroku.txt'))
  end

  def stub_dump_structure
    runner.stub(:run).with(/pg_dump .* -s /)
  end

  def stub_restore_structure
    runner.stub(:run).with(/pg_restore .* -s /)
  end

  def stub_dump_data
    runner.stub(:run).with(/pg_dump .* -a /)
  end

  def stub_restore_data
    runner.stub(:run).with(/pg_restore .* -a /)
  end

  def stub_reset_target
    runner.stub(:run).with(/bundle exec rake db:drop db:create/)
    runner.stub(:run).with(/heroku pg:reset/)
  end

  def invoke_cli(command, options = nil)
    options ||= {}
    script = Ohsnap::CLI::Root.new
    script.invoke(command, [], {
      config: 'spec/config/simple.yml',
      source: source,
      target: target
    }.merge(options))
  end
end
