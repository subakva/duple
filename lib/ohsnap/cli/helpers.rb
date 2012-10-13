require 'yaml'

module Ohsnap
  module CLI
    module Helpers

      def self.included(base)
        base.send(:include, Thor::Actions)
        base.send(:include, InstanceMethods)
        base.send(:extend, ClassMethods)
      end

      module ClassMethods
        def source_root
          File.expand_path(File.join(File.dirname(__FILE__), '../../..'))
        end

        def source_option
          class_option :source,
            desc: 'The name of the source environment.',
            type: :string,
            aliases: '-s'
        end

        def target_option
          class_option :target,
            desc: 'The name of the target environment.',
            type: :string,
            aliases: '-t'
        end

        def group_option
          class_option :group,
            desc: 'Name of the group configuration to use when dumping source data.',
            type: :string,
            aliases: '-g'
        end

        def capture_option
          class_option :capture,
            desc: 'Capture a new source snapshot before refreshing.',
            type: :boolean,
            aliases: '-c'
        end

        def tables_option
          class_option :tables,
            desc: 'A list of tables to include when dumping source data.',
            type: :array,
            aliases: '-t'
        end
      end

      module InstanceMethods
        def app_config_path
          File.join('config', 'ohsnap.yml')
        end

        def default_target
          'FAIL'
        end

        def default_source
          'FAIL'
        end

        def load_config
          config_path = File.join(destination_root, app_config_path)
          config_data = File.read(config_path)
          erbed = ERB.new(config_data).result
          YAML.load(erbed) || {}
        end
      end
    end
  end
end
