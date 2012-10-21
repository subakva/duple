module Duple

  # Decorates a Duple::Runner instance with helper methods for executing
  # PostgreSQL commands.
  class PGRunner
    def initialize(runner)
      @runner = runner
    end

    def pg_dump(flags, dump_file, db_config)
      pg_command('pg_dump', flags, db_config, nil, "> #{dump_file}")
    end

    def pg_restore(flags, dump_file, db_config)
      pg_command('pg_restore', flags, db_config, '-d', "< #{dump_file}")
    end

    def pg_command(pg_command, flags, db_config, db_flag, tail = nil)
        command = []
        command << %{PGPASSWORD="#{db_config[:password]}"}
        command << pg_command
        command << flags
        command << %{-h #{db_config[:host]} -U #{db_config[:username]} -p #{db_config[:port]}}
        command << db_flag if db_flag
        command << db_config[:database]
        command << tail if tail
        @runner.run(command.join(' '))
    end
  end
end
