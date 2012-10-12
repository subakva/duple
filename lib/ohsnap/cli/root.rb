require 'ohsnap/version'
require 'thor'
require 'thor/group'

module Ohsnap
  module CLI
    class Root < Thor
      include Thor::Actions
    end
  end
end
