require_relative "../cloud_compute"

module VagrantPlugins
  module Filoo
    module Action
      # This starts a stopped instance.
      class StopInstance
        STOP_RESOURCE = "/vserver/stop"
        STOP_INSTANCE_TIMEOUT = 60
        def initialize(app, env)
          @app    = app
          @baseUrl =env[:machine].provider_config.filoo_api_entry_point
          @apiKey = env[:machine].provider_config.filoo_api_key
        end

        def call(env)
          if env[:machine].state.id == :stopped
            env[:ui].info(I18n.t("vagrant_filoo.already_status", :status => env[:machine].state.id))
          else
            vmid = env[:machine].id
            env[:ui].info("Halt machine #{vmid}")
            env[:result] = VagrantPlugins::Filoo::CloudCompute::stopInstance vmid, @baseUrl, @apiKey
            env[:ui].info("Machine #{vmid} successfully halted, state #{env[:result].to_json}")
          end      
          @app.call(env)
        end
        
      end
    end
  end
end