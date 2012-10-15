require 'spec_helper'
require 'fileutils'

describe Ohsnap::Runner do

  let(:test_dir) { 'tmp' }
  let(:test_file) { "#{test_dir}/spawnbag.txt" }
  let(:log) { StringIO.new }
  after { log.close }

  before { FileUtils.mkdir_p(test_dir) }
  after { FileUtils.rm(test_file) if File.exists?(test_file) }

  context 'in live mode' do
    let(:runner) { Ohsnap::Runner.new(log: log) }

    it 'executes a command' do
      runner.run("touch #{test_file}")

      Pathname.new(test_file).should exist
    end

    it 'captures the output of the command' do
      result = runner.capture("cat #{__FILE__}")
      result.should =~ /captures the output of the command/
    end

    it 'writes the commands to the log' do
      runner.run("touch #{test_file}")
      log.string.should == " * Running: touch tmp/spawnbag.txt\n"
    end

    it 'raises an error if the command fails' do
      expect {
        runner.capture("cat NOT_A_REAL_FILE")
      }.to raise_error(RuntimeError, /Command failed: pid \d+ exit 1/)
    end
  end

  context 'in dry run mode' do
    let(:runner) { Ohsnap::Runner.new(dry_run: true, log: log) }

    it 'does not actually run the commands' do
      runner.run("touch #{test_file}")

      Pathname.new(test_file).should_not exist
    end

    it 'writes the commands to the log' do
      runner.run("touch #{test_file}")
      log.string.should == " * Running: touch tmp/spawnbag.txt\n"
    end
  end

  context 'with a recorder' do
    let(:recorder) { StringIO.new }
    let(:runner) { Ohsnap::Runner.new(recorder: recorder, log: log) }

    it 'logs commands to a file' do
      runner.capture('ls tmp')
      runner.capture('date')
      recorder.string.split("\n").should == ['ls tmp', 'date']
    end
  end
end
