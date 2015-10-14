module VagrantPlugins
  module Filoo
    module Action
      class MessageAlreadyCreated
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info(I18n.t("vagrant_filoo.already_created", :id => env[:machine].id))
          @app.call(env)
        end
      end
    end
  end
end
