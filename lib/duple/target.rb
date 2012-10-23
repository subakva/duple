module Duple
  # Represents the target of the data/schema transfer.
  class Target
    include Duple::Endpoint

    def environment
      config.target_environment
    end

    def name
      @name ||= config.target_name
    end
  end
end
