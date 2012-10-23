module Duple
  # Represents the source of the data/schema transfer.
  class Source
    include Duple::Endpoint

    def environment
      config.source_environment
    end

    def name
      @name ||= config.source_name
    end
  end
end
