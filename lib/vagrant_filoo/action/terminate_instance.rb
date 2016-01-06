require_relative "../cloud_compute"
module VagrantPlugins
  module Filoo
    module Action
      # This starts a stopped instance.
      class TerminateInstance
        include VagrantPlugins::Filoo::CloudCompute
        DELETE_SERVER_TIMEOUT = 30
        def initialize(app, env)
          @app = app
          @baseUrl = env[:machine].provider_config.filoo_api_entry_point
          @apiKey = env[:machine].provider_config.filoo_api_key
        end

        def call(env)
          vmid = env[:machine].id
          env[:result] = VagrantPlugins::Filoo::CloudCompute::deleteServer(vmid, @baseUrl, @apiKey)
          env[:ui].info("Machine #{env[:machine].id} successfully terminated")
          env[:machine].id = nil
          @app.call(env)
        end
      end
    end
  end
end