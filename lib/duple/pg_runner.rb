module Duple

  # Decorates a Duple::Runner instance with helper methods for executing
  # PostgreSQL commands.
  class PGRunner
    def initialize(runner)
      @runner = runner
    end

    def pg_dump(flags, dump_file, credentials)
      pg_command('pg_dump', flags, credentials, nil, "> #{dump_file}")
    end

    def pg_restore(flags, dump_file, credentials)
      pg_command('pg_restore', flags, credentials, '-d', "< #{dump_file}")
    end

    def pg_command(pg_command, flags, credentials, db_flag, tail = nil)
        command = []
        command << %{PGPASSWORD="#{credentials[:password]}"}
        command << pg_command
        command << flags
        command << %{-h #{credentials[:host]} -U #{credentials[:user]} -p #{credentials[:port]}}
        command << db_flag if db_flag
        command << credentials[:db]
        command << tail if tail
        @runner.run(command.join(' '))
    end
  end
end
