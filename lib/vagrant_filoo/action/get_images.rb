require_relative '../errors'

module VagrantPlugins
  module Filoo
    module Action
      class GetImages

        def initialize(app, env)
          @app    = app
          @baseUrl =env[:machine].provider_config.filoo_api_entry_point()
          @apiKey = env[:machine].provider_config.filoo_api_key()
        end
        def call(env)
          env[:images]= VagrantPlugins::Filoo::CloudCompute::getAutoInstallImages(@baseUrl, @apiKey)
          env[:result] = env[:images]
          @app.call(env)
        end
      end
    end
  end
end