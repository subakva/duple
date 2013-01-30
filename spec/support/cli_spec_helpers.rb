module Duple
  module CLISpecHelpers
    def self.included(base)
      base.send(:let, :runner) { double_runner }
      base.send(:let, :source) { 'stage' }
      base.send(:let, :target) { 'development' }
      base.send(:let, :snapshot_dir) { 'tmp/duple' }
      base.send(:let, :snapshot_path) { 'tmp/duple/stage-2012-10-19-03-09-30.dump' }
    end

    def double_runner
      runner = fire_double('Duple::Runner')
      Duple::Runner.stub(:new).and_return(runner)
      runner
    end

    def heroku_pgbackups_url_response
      File.read('spec/config/heroku_pgbackups_url.txt')
    end

    def heroku_pgbackups_response
      File.read('spec/config/heroku_pgbackups.txt')
    end

    def heroku_config_response
      File.read('spec/config/heroku_config.txt')
    end

    def stub_prerefresh_tasks
      runner.stub(:run).with(/heroku run "rake refresh:prepare/)
      runner.stub(:run).with(/rake refresh:prepare/)
      runner.stub(:run).with(/heroku maintenance:on/)
    end

    def stub_postrefresh_tasks
      runner.stub(:run).with(/heroku run "rake refresh:finish/)
      runner.stub(:run).with(/rake refresh:finish/)
      runner.stub(:run).with(/heroku maintenance:off/)
    end

    def stub_fetch_url
      runner.stub(:capture).with(/heroku pgbackups:url/)
        .and_return(heroku_pgbackups_url_response)
    end

    def stub_fetch_config
      runner.stub(:capture).with(/heroku config/)
        .and_return(heroku_config_response)
    end

    def stub_fetch_backups
      runner.stub(:capture).with(/heroku pgbackups /)
        .and_return(heroku_pgbackups_response)
    end

    def stub_download_snapshot
      runner.stub(:run).with(/mkdir -p/)
      runner.stub(:run).with(/curl/)
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

    def stub_restore_url
      runner.stub(:run).with(/heroku pgbackups:restore .* -a /)
    end

    def stub_restore_data
      runner.stub(:run).with(/pg_restore .* -a /)
    end

    def stub_reset_heroku
      runner.stub(:run).with(/heroku pg:reset/)
    end

    def stub_reset_local
      runner.stub(:run).with(/bundle exec rake db:drop db:create/)
    end

    def invoke_cli(command, options = nil)
      options ||= {}
      script = Duple::CLI::Root.new
      script.invoke(command, [], {
        config: 'spec/config/simple.yml',
        source: source,
        target: target
      }.merge(options))
    end
  end
end
