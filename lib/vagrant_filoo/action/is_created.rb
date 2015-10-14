module VagrantPlugins
  module Filoo
    module Action
      class IsCreated
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:result] = true
          if env[:machine].state.id == :not_created
            env[:result] = false
          end
          if env[:machine].state.id == :deleted
            env[:result] = false
          end
          @app.call(env)
        end
      end
    end
  end
end