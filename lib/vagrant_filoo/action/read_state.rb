require_relative "../cloud_compute"
require "vagrant/machine_state"


module VagrantPlugins
  module Filoo
    module Action
      class  ReadState
        include VagrantPlugins::Filoo::CloudCompute
        SERVERSTATUS_RESOURCE = '/vserver/status'
        def initialize(app, env)
          @app    = app
          @baseUrl ="#{env[:machine].provider_config.filoo_api_entry_point}"
          @apiKey = env[:machine].provider_config.filoo_api_key()
        end
        
        def call(env)
          vmid = env[:machine].id
          begin
            serverStatus = VagrantPlugins::Filoo::CloudCompute::getServerStatus(vmid, @baseUrl, @apiKey)
            env[:machine_state_id] = machineStateIdFromState(serverStatus)
          rescue VagrantPlugins::Filoo::Errors::FilooApiError => e
            errorCode = nil;
            begin
              errorCode = JSON.parse(e.message)["code"]
            rescue JSON::ParserError => jsonErr
              raise e
            end
            if  errorCode == 403
              env[:machine_state_id] = :not_created
            else
              raise e
            end
            en
         end
         @app.call(env)
        end
        
        def machineStateIdFromState(serverStatus)
          case serverStatus["vmstatus"]
          when "running"
            return :running
          when "stopped"
            return :stopped
          when "processing_autoinstall"
            return :processing_autoinstall
          when "disabled"
            return :disabled
          when "activated"
            return :activated
          when "deleted"
            return :deleted
          when "unknown"
            return :unknown
          end
        end
        
      end
    end
  end
end