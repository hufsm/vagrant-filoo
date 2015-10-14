require_relative "../cloud_compute"

module VagrantPlugins
  module Filoo
    module Action
      class StartInstance
        include VagrantPlugins::Filoo::CloudCompute
        
        def initialize(app, env)
          @app    = app
          @baseUrl =env[:machine].provider_config.filoo_api_entry_point
          @apiKey = env[:machine].provider_config.filoo_api_key
        end

        def call(env)
          env[:metrics] ||= {}
          vmid = env[:machine].id
          env[:result] = VagrantPlugins::Filoo::CloudCompute::startInstance(vmid, @baseUrl, @apiKey) 
          env[:ui].info("Machine #{vmid} successfully started, state #{env[:result].to_json}")
          @app.call(env)
        end
      end
    end
  end
end