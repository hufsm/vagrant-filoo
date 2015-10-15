require "log4r"
require_relative "../cloud_compute"
require 'vagrant_filoo/util/timer'

module VagrantPlugins
  module Filoo
    module Action
      class StartInstance
        include VagrantPlugins::Filoo::CloudCompute
        
        def initialize(app, env)
          @app    = app
          @baseUrl =env[:machine].provider_config.filoo_api_entry_point
          @apiKey = env[:machine].provider_config.filoo_api_key
          @logger = Log4r::Logger.new("vagrant_filoo::action::start_instance")
        end

        def call(env)
          env[:metrics] ||= {}
          vmid = env[:machine].id
          env[:result] = VagrantPlugins::Filoo::CloudCompute::startInstance(vmid, @baseUrl, @apiKey) 
          env[:ui].info("Machine #{vmid} successfully started, state #{env[:result].to_json}")
          @logger.info("Time to instance ready: #{env[:metrics]["instance_ready_time"]}")

          if !env[:interrupted]
            env[:metrics]["instance_ssh_time"] = Util::Timer.time do
              # Wait for SSH to be ready.
              env[:ui].info(I18n.t("vagrant_filoo.waiting_for_ssh"))
              while true
                # If we're interrupted then just back out
                break if env[:interrupted]
                break if env[:machine].communicate.ready?
                sleep 2
              end
            end

            @logger.info("Time for SSH ready: #{env[:metrics]["instance_ssh_time"]}")

            # Ready and booted!
            env[:ui].info(I18n.t("vagrant_filoo.ready"))
          end
          @app.call(env)
        end
      end
    end
  end
end