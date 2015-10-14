require_relative "../cloud_compute"

module VagrantPlugins
  module Filoo
    module Action
      class CreateServer
        def initialize(app, env)
          @app    = app
          @baseUrl =env[:machine].provider_config.filoo_api_entry_point
          @apiKey = env[:machine].provider_config.filoo_api_key
        end
        
        def call(env)
          puts env[:machine].provider_config.filoo_api_entry_point
          puts env[:machine].provider_config.type
          
          if (env[:images].nil?)
            raise Errors::ImagesNotLoaded
          end
          config  = env[:machine].provider_config
          imageId = "#{env[:images][config.cd_image_name]}".to_i
          params = {
            :type => config.type,
            :cpu => config.cpu,
            :ram => config.ram,
            :hdd => config.hdd,
            :cd_imageid => imageId
          }
          env[:ui].info("vagrant_filoo creating_instance")
          env[:ui].info(" -- Type: #{config.type}")
          env[:ui].info(" -- CPUs: #{config.cpu}")
          env[:ui].info(" -- Ram: #{config.ram}")
          env[:ui].info(" -- Image Id: #{imageId}")
          env[:ui].info(" -- Image Name: #{config.cd_image_name}")
          env[:result] = VagrantPlugins::Filoo::CloudCompute::createServer(params, @baseUrl, @apiKey)
          env[:machine].id = env[:result]["vmid"]
          #env[:machine].name  = env[:result]["custom_vmname"]
          env[:ui].info(" -- Server created, server state #{env[:result]}")
          @app.call(env)
        end
      end
    end
  end
end
