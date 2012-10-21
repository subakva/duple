require 'spec_helper'

describe Duple::Configuration do


  describe '#db_config' do
    let(:config_hash) { YAML.load(File.read('spec/config/simple.yml'))}

    it 'supplies default database values for a local environment' do
      config = Duple::Configuration.new(config_hash, {})
      c = config.db_config('development')
      c[:username].should == 'postgres'
      c[:password].should == ''
      c[:host].should == 'localhost'
      c[:port].should == '5432'
    end

    context 'with all db config parameters' do
      let(:db_config_hash) {
        db_hash = config_hash['environments']['development']
        db_hash['username'] = 'config_username'
        db_hash['password'] = 'config_password'
        db_hash['host'] = 'config_host'
        db_hash['port'] = '6022'
        db_hash['database'] = 'config_database'
        config_hash
      }
      let(:config) { Duple::Configuration.new(db_config_hash, {}) }
      subject(:db_config) { config.db_config('development') }

      it 'loads the options from the config' do
        db_config[:username].should == 'config_username'
        db_config[:password].should == 'config_password'
        db_config[:host].should == 'config_host'
        db_config[:port].should == '6022'
        db_config[:database].should == 'config_database'
      end
    end

    it 'fails if the database name is missing' do
      config_hash['environments']['development'].delete('database')
      config = Duple::Configuration.new(config_hash, {})

      expect {
        config.db_config('development')
      }.to raise_error(
        ArgumentError,
        'Invalid config: "database" is required for a local environment.'
      )
    end
  end

  describe '#excluded_tables' do
    let(:config_hash) { YAML.load(File.read('spec/config/groups.yml'))}

    context 'with neither tables nor group options' do
      it 'returns an empty array' do
        config = Duple::Configuration.new(config_hash, {})
        config.excluded_tables.should == []
      end
    end

    context 'with the group option' do
      it 'returns the tables specified by the group' do
        config = Duple::Configuration.new(config_hash, {group: 'no_comments'})
        config.excluded_tables.should == ['comments']
      end

      context 'with an include_all group' do
        it 'returns the tables specified by the group' do
          config = Duple::Configuration.new(config_hash, {group: 'all_but_comments'})
          config.excluded_tables.should == ['comments']
        end
      end
    end

    context 'with both tables and group options' do
      it 'does not exclude tables in the tables option' do
        config = Duple::Configuration.new(config_hash, {
          group: 'no_comments',
          tables: ['comments']
        })
        config.included_tables.should == ['comments']
        config.excluded_tables.should == []
      end

      context 'with an include_all group' do
        it 'does not exclude tables in the tables option' do
          config = Duple::Configuration.new(config_hash, {
            group: 'all_but_comments',
            tables: ['comments']
          })
          config.included_tables.should == []
          config.excluded_tables.should == []
        end
      end
    end
  end

  describe '#included_tables' do
    let(:config_hash) { YAML.load(File.read('spec/config/groups.yml'))}

    context 'with neither tables nor group options' do
      it 'returns an empty array' do
        config = Duple::Configuration.new(config_hash, {})
        config.included_tables.should == []
      end
    end

    context 'with the tables option' do
      it 'returns the tables specified in the option value' do
        config = Duple::Configuration.new(config_hash, {tables: ['categories']})
        config.included_tables.should == ['categories']
      end
    end

    context 'with the group option' do
      it 'returns the tables specified by the group' do
        config = Duple::Configuration.new(config_hash, {group: 'minimal'})
        config.included_tables.should == ['categories', 'links']
      end

      context 'with an include_all group' do
        it 'returns an empty array' do
          config = Duple::Configuration.new(config_hash, {group: 'all'})
          config.included_tables.should == []
        end
      end
    end

    context 'with both tables and group options' do
      it 'returns all tables in the group and the option value' do
        config = Duple::Configuration.new(config_hash, {
          group: 'minimal',
          tables: ['posts', 'comments']
        })
        config.included_tables.should == ['categories', 'comments', 'links', 'posts']
      end

      context 'with an include_all group' do
        it 'returns an empty array' do
          config = Duple::Configuration.new(config_hash, {
            group: 'all',
            tables: ['posts', 'comments']
          })
          config.included_tables.should == []
        end
      end
    end
  end

  describe '#source_environment' do
    let(:config_hash) { YAML.load(File.read('spec/config/simple.yml'))}

    it 'gets the default source environment' do
      config = Duple::Configuration.new(config_hash, {})
      config.source_environment.should_not be_nil
      config.source_environment['appname'].should == 'duple-stage'
    end

    it 'gets the source environment' do
      config = Duple::Configuration.new(config_hash, { source: 'production' })
      config.source_environment.should_not be_nil
      config.source_environment['appname'].should == 'duple-production'
    end

    it 'does not allow multiple default sources' do
      config_hash['environments']['backstage'] = {'default_source' => true}
      config = Duple::Configuration.new(config_hash, {})
      expect {
        config.source_environment
      }.to raise_error(ArgumentError, 'Only a single environment can be default_source.')
    end
  end

  describe '#target_environment' do
    let(:config_hash) { YAML.load(File.read('spec/config/simple.yml'))}

    it 'gets the default target environment' do
      config = Duple::Configuration.new(config_hash, {})
      config.target_environment.should_not be_nil
      config.target_environment['type'].should == 'local'
    end

    it 'gets the target environment' do
      config = Duple::Configuration.new(config_hash, { target: 'stage' })
      config.target_environment.should_not be_nil
      config.target_environment['appname'].should == 'duple-stage'
    end

    it 'fails if the target is not allowed' do
      config = Duple::Configuration.new(config_hash, { target: 'production' })
      expect {
        config.target_environment
      }.to raise_error(ArgumentError, 'Invalid target: production is not allowed to be a target.')
    end

    it 'does not allow multiple default targets' do
      config_hash['environments']['backstage'] = {'default_target' => true}
      config = Duple::Configuration.new(config_hash, {})
      expect {
        config.target_environment
      }.to raise_error(ArgumentError, 'Only a single environment can be default_target.')
    end

    it 'allows multiple disallowed targets' do
      config_hash['environments']['reporting'] = {'allow_target' => false}
      config = Duple::Configuration.new(config_hash, {})
      expect {
        config.target_environment
      }.to_not raise_error(ArgumentError, 'Only a single environment can be allow_target.')
    end
  end
end
