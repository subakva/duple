module Duple
  class HerokuRunner
    def initialize(runner)
      @runner = runner
    end

    def run(appname, args, tail = nil)
      @runner.run(heroku_command(appname, args, tail))
    end

    def capture(appname, args, tail = nil)
      @runner.capture(heroku_command(appname, args, tail))
    end

    protected

    def heroku_command(appname, args, tail = nil)
      command = []
      command << %{heroku #{args}}
      command << %{-a #{appname}}
      command << %{tail} if tail
      command.join(' ')
    end
  end
end
