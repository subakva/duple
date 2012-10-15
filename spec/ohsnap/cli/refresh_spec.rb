require 'spec_helper'

describe Ohsnap::CLI::Refresh do
  it 'does something' do
    script = Ohsnap::CLI::Root.new
    script.invoke(:refresh)
  end

  # context 'from heroku to heroku'
  # context 'from heroku to local'
  # context 'from local to heroku'
end
