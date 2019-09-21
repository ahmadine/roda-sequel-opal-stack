class Roda
  module RodaPlugins
    module RackEnv
      def dev?
        ENV['RACK_ENV'] == 'development'
      end

      def prod?
        ENV['RACK_ENV'] == 'production'
      end

      module ClassMethods
        include RackEnv
      end

      module InstanceMethods
        include RackEnv
      end
    end

    register_plugin(:rack_env, RackEnv)
  end
end