require "vagrant"

module VagrantPlugins
  module Filoo
    module Errors

      class VagrantFilooError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_filoo.errors")
      end
      
      class ImagesNotLoaded < VagrantFilooError
        error_key "images_not_loaded"
      end
      
      class ConfigError < VagrantFilooError
        error_key("config_error")
      end

      class UnexpectedStateError < VagrantFilooError
        error_key(:unexpected_state_error)
      end
      
      class FilooApiError < VagrantFilooError
        error_key(:filoo_api_error)
      end
      
      class FilooJobFailedError < VagrantFilooError
        error_key("filoo_job_failed_error")
      end
      
      class FilooJobResultTimeoutError < VagrantFilooError
        error_key(:filoo_job_result_timeout_error)
      end
      
      class StartInstanceTimeout < VagrantFilooError
        error_key(:start_instance_timeout)
      end
      
      class StopInstanceTimeout < VagrantFilooError
        error_key(:stop_instance_timeout)
      end

      class CreateInstanceTimeout < VagrantFilooError
        error_key(:create_instance_timeout)
      end
      
      class DeleteInstanceTimeout < VagrantFilooError
        error_key(:delete_instance_timeout)
      end
            
      class RsyncError < VagrantFilooError
        error_key(:rsync_error)
      end

      class MkdirError < VagrantFilooError
        error_key(:mkdir_error)
      end      
    end
  end
end