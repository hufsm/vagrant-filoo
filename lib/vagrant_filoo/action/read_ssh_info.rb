require 'json'
require_relative "../cloud_compute"


module VagrantPlugins
  module Filoo
    module Action
      class ReadSSHInfo
        def initialize(app, env)
          @app    = app
          @baseUrl =env[:machine].provider_config.filoo_api_entry_point()
          @apiKey = env[:machine].provider_config.filoo_api_key()
        end
        def call(env)
          vmid = vmid = env[:machine].id
          serverStatus = VagrantPlugins::Filoo::CloudCompute::getServerStatus(vmid, @baseUrl, @apiKey)
          if serverStatus["network_settings"].nil?
            raise VagrantPlugins::Filoo::Errors::UnexpectedStateError,
              resource: VagrantPlugins::Filoo::CloudCompute::SERVERSTATUS_RESOURCE,
              state: serverStatus,
              message: "Unexpected State of server status " + serverList.to_json,
              description: "Server with vmid #{vmid} should have server status with field network_settings present"
          end
          
          if serverStatus["network_settings"].length < 1 or serverStatus["network_settings"][0]["ipadress"].nil?
            raise VagrantPlugins::Filoo::Errors::UnexpectedStateError,
                   resource: VagrantPlugins::Filoo::CloudCompute::SERVERSTATUS_RESOURCE,
                   state: serverStatus,
            description: "Server with vmid #{vmid} should have server status with subfield field ipadress network_settings present"
          end
          env[:machine_ssh_info] = { :host => serverStatus["network_settings"][0]["ipadress"], 
            :port => 22 , 
            :username => "root"
            }
          @app.call(env)
        end
      end
    end
end
end