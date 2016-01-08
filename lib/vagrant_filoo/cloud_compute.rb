require 'rest-client'
require_relative 'errors'
require 'json'

module VagrantPlugins
  module Filoo
    module CloudCompute
      LOGGER = Log4r::Logger.new('vagrant_filoo::cloud_compute')

      ################################
      # Application specific methods #
      ################################
      CREATE_SERVER_RESOURCE = '/vserver/create'
      DELETE_SERVER_RESOURCE = '/vserver/delete'
      LIST_SERVER_RESOURCE ='/vserver/list'
      SERVERSTATUS_RESOURCE = '/vserver/status'
      START_RESOURCE = '/vserver/start'
      STOP_RESOURCE = '/vserver/stop'
      LIST_NIC_RESOURCE = '/vserver/list_nic'
      ADD_NIC_RESOURCE = '/vserver/add_nic'
      DELETE_NIC_RESOURCE = '/vserver/del_nic'
      
      ########################################
      # Virtual Server Creation and checking #
      ########################################

      CREATE_SERVER_TIMEOUT = 30
      VALID_TYPES = ['dynamic','fixed']
      VALID_CPU_COUNTS = [1, 2, 3, 4, 5, 6, 7, 8]
      VALID_RAM = [128, 256, 512, 1024, 2048, 3072, 4096, 5120, 6144, 7186, 8192]

      #####################################################################
      # create a virtual server with the given parameters
      # parameters {hash} with following fields
      #     -type=(dynamic|fixed) : dynmaic (minutely) or vServer (monthly)
      #     -cpu=(1-8): Anzahl vCPUs
      #     -ram=(128,256,512,1024,2048,3072,4096,5120,6144,7186,8192): Ram in MB
      #     -hdd=(10-2000): HDDp Space in GB, 10GB-Steps (10,20,30,...)
      #     -cd_imageid ID. Only for images with autoinstall=1.
      ####################################################################

      def self.createServer(baseUrl, apiKey, filooConfig, imageId)
        params = {
          :type => filooConfig.type,
          :cpu => filooConfig.cpu,
          :ram => filooConfig.ram,
          :hdd => filooConfig.hdd,
          :cd_imageid => imageId,
          :additional_nic => filooConfig.additional_nic
        }
        checkServerParams(params)
        createServerUrl = baseUrl +  CREATE_SERVER_RESOURCE
        jobId = call4JobId createServerUrl, apiKey, params
        vmid = nil;
        jobResult = nil

        begin
          jobResult = waitJobDone(jobId, baseUrl, apiKey, CREATE_SERVER_TIMEOUT)
          vmid = jobResult[:result]['vmid']

          if jobResult[:result]['vmid'].nil?
            raise VagrantPlugins::Filoo::Errors::FilooApiError,
              code: 500,
              message: "Unexpected return value to Api Call POST " +  createServerUrl + " #{params} " + {:jobid => jobId}.to_json,
              description: "Response has no field vmid in result. Response:  " + jobResult.to_json
          end

        rescue VagrantPlugins::Filoo::Errors::FilooJobResultTimeoutError => e
          raise VagrantPlugins::Filoo::Errors::CreateInstanceTimeout,
            job_id: jobId,
            timeout: e.timeout
        rescue VagrantPlugins::Filoo::Errors::FilooJobFailedError => e
          vmid = jobResult[:result]['vmid']
        end
         
         serverStatus = nil;
         checkParams = {:type => params[:type],
           :cpu => params[:cpu],
           :ram => params[:ram],
           :hdd => params[:hdd]}

         begin
           serverStatus = self.checkServerStatus(vmid, checkParams, baseUrl, apiKey)
           rescue VagrantPlugins::Filoo::Errors::FilooApiError => e

             if e.code == 403
               raise VagrantPlugins::Filoo::Errors::UnexpectedStateError,
                 resource: LIST_SERVER_RESOURCE,
                 jobid: jobResult[:jobid],
                   job_command: jobResult[:job_command],
                   state: serverList,
                   message: "Unexpected State of server list " + serverList.to_json,
                   description: "Server with vmid #{vmid} should have been created "
                     + "(see #{baseUrl}#{LIST_SERVER_RESOURCE} action : list) "
                     + "Server is not created though system gave feedback with status #{jobResult[:status]} "
                     + "to task  #{jobResult[:job_command]} #{jobResult[:job_param]} with jobid #{jobResult[:jobid]}"
             end

             raise e
         end
         
         if params[:additional_nic]
           self.addNic(vmid, baseUrl, apiKey)
           self.stopInstance(vmid, baseUrl, apiKey)
           self.startInstance(vmid, baseUrl, apiKey, filooConfig)
         end 
         serverStatus
      end
      
      def self.checkServerParams params

        if !params.is_a?(Hash)
           raise VagrantPlugins::Filoo::Errors::ConfigError,
             message: "Invalid type of parameter params, must be Hash but is #{params.class}"
        end
 
        if params[:type].nil? or ! ['dynamic','fixed'].include? params[:type]
          raise VagrantPlugins::Filoo::Errors::ConfigError,
            message: "Invalid value #{params[:type]} for configuration field type, must be one of the following numbers #{VALID_TYPES}"
        end

        if params[:cpu].nil? or ! VALID_CPU_COUNTS.include? params[:cpu]
          raise VagrantPlugins::Filoo::Errors::ConfigError,
            message: "Invalid value #{params[:cpu]} for configuration field cpu, must be one of the following numbers #{VALID_CPU_COUNTS}"
        end

        if params[:ram].nil? or ! VALID_RAM.include? params[:ram]
          raise VagrantPlugins::Filoo::Errors::ConfigError,
            message: "Invalid value #{params[:ram]} for configuration field ram, must be one of the following numbers #{VALID_RAM.to_json}"
        end
 
        if params[:hdd].nil? or params[:hdd] < 10  or params[:hdd] > 2000 or params[:hdd] % 10 != 0
          raise VagrantPlugins::Filoo::Errors::ConfigError,
            message: "Invalid value #{params[:hd]} for configuration field hd, must be a number between 10-2000 "
              + " with steps of 10,20,30..."
        end

      end
      
      # Server removal
      DELETE_SERVER_TIMEOUT = 30
      
      def self.deleteServer(vmid, baseUrl, apiKey)
        deleteServereUrl = baseUrl +  DELETE_SERVER_RESOURCE
        jobId = call4JobId deleteServereUrl, apiKey, {:vmid => vmid}
        jobResult = nil;

        begin
          jobResult = waitJobDone(jobId, baseUrl, apiKey, DELETE_SERVER_TIMEOUT)
        rescue VagrantPlugins::Filoo::Errors::FilooJobResultTimeoutError => e
          raise VagrantPlugins::Filoo::Errors::DeleteInstanceTimeout,
            job_id: jobId,
            timeout: e.timeout
        end

        serverList = self.getServers(baseUrl + LIST_SERVER_RESOURCE, apiKey)

        if !serverList["#{vmid}"].nil?
          raise VagrantPlugins::Filoo::Errors::UnexpectedStateError,
            resource: LIST_SERVER_RESOURCE,
            jobid: jobResult[:jobid],
            job_command: jobResult[:job_command],
            state: serverList,
            message: "Unexpected State of server list " + serverList.to_json,
            description: "Server with vmid #{vmid} should have been deleted from server list but is not "
            + "(see #{baseUrl}#{LIST_SERVER_RESOURCE} action : list) "
            + "though system gave feedback with status #{jobResult[:status]} to task  "
            + "#{jobResult[:job_command]} #{jobResult[:job_param]} with jobid #{jobResult[:jobid]}" 
        end

        return serverList
      end
      
      # start server
      
      START_INSTANCE_TIMEOUT = 60
      
      def self.startInstance(vmid, baseUrl, apiKey, filooConfig)

        shouldNotChangeParams = {
          :type => filooConfig.type,
          :cpu => filooConfig.cpu,
          :ram => filooConfig.ram,
          :hdd => filooConfig.hdd
        }

        begin
          compareServerStatus(vmid, shouldNotChangeParams, baseUrl, apiKey)
        rescue VagrantPlugins::Filoo::Errors::InvaildServerParameterError => e
          paramKey = "#{e.paramName}"
          raise VagrantPlugins::Filoo::Errors::ConfigError,
            message: "Can not update filoo provider parameter '#{e.paramName}'. Parameter 'filoo.#{e.paramName}' must be set to #{e.serverStatus[paramKey]}. 
             Please create new instance if you need updated this parameters."
        end
          
        nicList = self.listNic(vmid, baseUrl, apiKey) 
        
        if filooConfig.additional_nic && nicList.count < 1
          self.addNic(vmid, baseUrl, apiKey)
          self.stopInstance(vmid, baseUrl, apiKey)
          self.startInstance(vmid, baseUrl, apiKey, filooConfig)
        elsif !filooConfig.additional_nic && nicList.count > 0
          self.deleteNic(vmid, baseUrl, apiKey)
          self.stopInstance(vmid, baseUrl, apiKey)
          self.startInstance(vmid, baseUrl, apiKey, filooConfig)
        end
        
        url = "#{baseUrl}#{START_RESOURCE}"
        jobId = call4JobId url, apiKey, {:vmid => vmid}
        jobResult = nil;

        begin
          jobResult = waitJobDone(jobId, baseUrl, apiKey, START_INSTANCE_TIMEOUT)
        rescue VagrantPlugins::Filoo::Errors::FilooJobResultTimeoutError => e
          raise VagrantPlugins::Filoo::Errors::StartInstanceTimeout,
            job_id: jobId,
            timeout: e.timeout
        end

        serverStatus = nil;

        begin
          serverStatus = checkServerStatus(vmid, {:vmid => vmid, :vmstatus => "running"}, baseUrl, apiKey)

          rescue VagrantPlugins::Filoo::Errors::FilooApiError => e
            if e.code == 403
              raise VagrantPlugins::Filoo::Errors::UnexpectedStateError,
                resource: LIST_SERVER_RESOURCE,
                jobid: jobResult[:jobid],
                  job_command: jobResult[:job_command],
                  state: serverList,
                  message: "Unexpected State of server list " + serverList.to_json,
                  description: "Server with vmid #{vmid} should be in list "
                    + "(see #{baseUrl}#{LIST_SERVER_RESOURCE} action : list) "
                    + "Server is not in list though system gave feedback with status #{jobResult[:status]} "
                    + "to task  #{jobResult[:job_command]} #{jobResult[:job_param]} with jobid #{jobResult[:jobid]}"
            end
            raise e
          end

          return serverStatus
        end
      
      # stop instance
      
      STOP_INSTANCE_TIMEOUT = 60
      
      def self.stopInstance(vmid, baseUrl, apiKey)
        stopInstanceUrl = baseUrl +  STOP_RESOURCE
        jobId = call4JobId(stopInstanceUrl, apiKey, {:vmid => vmid})
        jobResult = nil

        begin
          jobResult = waitJobDone(jobId, baseUrl, apiKey, STOP_INSTANCE_TIMEOUT)
        rescue VagrantPlugins::Filoo::Errors::FilooJobResultTimeoutError => e
          raise VagrantPlugins::Filoo::Errors::StopInstanceTimeout,
            job_id: jobId,
            timeout: e.timeout
        end

        serverStatus = nil;

        begin
          serverStatus = checkServerStatus(vmid, {:vmid => vmid, :vmstatus => "stopped"}, baseUrl, apiKey)
          rescue VagrantPlugins::Filoo::Errors::FilooApiError => e
            if e.code == 403
              raise VagrantPlugins::Filoo::Errors::UnexpectedStateError,
                resource: LIST_SERVER_RESOURCE,
                jobid: jobResult[:jobid],
                  job_command: jobResult[:job_command],
                  state: serverList,
                  message: "Unexpected State of server list " + serverList.to_json,
                  description: "Server with vmid #{vmid} should be in list "
                    + "(see #{baseUrl}#{LIST_SERVER_RESOURCE} action : list) "
                    + "Server is not in list though system gave feedback with status #{jobResult[:status]} "
                    + "to task  #{jobResult[:job_command]} #{jobResult[:job_param]} with jobid #{jobResult[:jobid]}"
            end
            raise e
        end

      end
      
      
      # list servers
      
      def self.getServers(baseUrl, apiKey)
        begin
          serverList = self.call(baseUrl + LIST_SERVER_RESOURCE,apiKey, {:detailed => false})['return']
          hashFromServerList(serverList)
        rescue ArgumentError => e
          raise ConfigError, e.message
        end
      end
      
      def self.hashFromServerList serverList
        serversHash = {}
        serverList.each { |serverInfo| 
          serversHash[serverInfo['vmid']] = serverInfo
          serversHash[serverInfo['vmid']].delete('vmid')
        }
        return serversHash
      end
      
      def self.hashFromServerList serverList
        serversHash = {}
        serverList.each { |serverInfo| 
          serversHash[serverInfo['vmid']] = serverInfo
          serversHash[serverInfo['vmid']].delete('vmid')
        }
        return serversHash
      end
      
      # list nic
      
      def self.listNic(vmid, baseUrl, apiKey)
        begin
          return self.call(baseUrl + LIST_NIC_RESOURCE, apiKey, {:vmid => vmid})['return']
        rescue ArgumentError => e
          raise VagrantPlugins::Filoo::Errors::ConfigError, message: e.message
        end
      end
        
      # add nic
      
      def self.addNic(vmid, baseUrl, apiKey)

        begin
          return self.call(baseUrl + ADD_NIC_RESOURCE, apiKey, {:vmid => vmid})['return']
        rescue ArgumentError => e
          raise VagrantPlugins::Filoo::Errors::ConfigError, message: e.message
        end
      end
  
      # delete nic
      
      def self.deleteNic(vmid, baseUrl, apiKey)

        begin
          return self.call(baseUrl + DELETE_NIC_RESOURCE, apiKey, {:vmid => vmid})['return']
        rescue ArgumentError => e
          raise VagrantPlugins::Filoo::Errors::ConfigError, message: e.message
        end
      end      
          
      # server status
      
      def self.getServerStatus(vmid, baseUrl, apiKey)

        if vmid.nil?
          return :not_created 
        end

        begin
          return self.call(baseUrl + SERVERSTATUS_RESOURCE, apiKey, {:vmid => vmid, :detailed => true})['return']
        rescue ArgumentError => e
          raise VagrantPlugins::Filoo::Errors::ConfigError, message: e.message
        end

      end

      def self.checkServerStatus(vmid, shouldParams, baseUrl, apiKey)
        
        begin
          return compareServerStatus(vmid, shouldParams, baseUrl, apiKey)
        rescue VagrantPlugins::Filoo::Errors::InvaildServerParameterError => e
          raise VagrantPlugins::Filoo::Errors::UnexpectedStateError,
            resource: SERVERSTATUS_RESOURCE,
            state: e.serverStatus,
            message: "Unexpected State of server " + serverStatus.to_json,
            description: "Server with vmid #{vmid} should have following params set " + shouldParams.to_json
              + " but has status " + e.serverStatus 
        end

      end
      
      #
      # Retrieves the Server status and compares it with the given shouldPramams
      #
      def self.compareServerStatus(vmid, shouldParams, baseUrl, apiKey)
        serverStatus = self.getServerStatus(vmid, baseUrl, apiKey)
        
        if serverStatus ==  :not_created 
          raise VagrantPlugins::Filoo::Errors::UnexpectedStateError, 
            state: serverStatus,
            message: "Unexpected State of server " + serverStatus.to_json
        end
        
        serverStatus = JSON.parse(serverStatus.to_json)
        shouldParams = JSON.parse(shouldParams.to_json)
        shouldParams.each do |key, value|
      
          if "#{value}" != "#{serverStatus[key]}"
            raise VagrantPlugins::Filoo::Errors::InvaildServerParameterError.new(key, serverStatus[key], serverStatus),
              resource: SERVERSTATUS_RESOURCE,
              invalidKey: key,
              invalidValue: value,
              state: serverStatus,
              message: "Unexpected State of server " + serverStatus.to_json,
              description: "Server with vmid #{vmid} should have following params set " + shouldParams.to_json
                + " but has status " + serverStatus 
          end
      
        end
        return serverStatus
      end
      
      #images
      IMAGES_RESOURCE = "/vserver/image"
      
      def self.getAutoInstallImages(baseUrl, apiKey)
        imageList = nil;
        begin
          imageList = self.call(baseUrl + IMAGES_RESOURCE, apiKey, {:action => "list"})['return']
        rescue ArgumentError => e
          raise ConfigError, e.message
        end
        autoInstallImagesHash = {}
        imageList.each { |imageInfo|
          if !imageInfo['cd'].nil? and imageInfo['autoinstall'] == 1
            autoInstallImagesHash[imageInfo['cd']] = imageInfo['cd_imageid']
          end
         }
        return autoInstallImagesHash;
      end
      
      #Image handling
 
      def self.hashAutoInstallListFromImageList serverList
        autoInstallImagesHash = {}
        serverList.each { |imageInfo| 
          if !imageInfo['cd'].nil? and imageInfo['autoinstall'] == 1
            autoInstallImagesHash[imageInfo['cd']] = imageInfo
            autoInstallImagesHash[imageInfo['cd']].delete("cd")
          end
        }
        return autoInstallImagesHash;
      end
      
      
     ##########################################
     # basic api call handling to https://api.filoo.de/api/v1/
     ############################################
     
     SHOWJOB_RESOURCE = "/jobqueue/show/"
     DEFAULT_TIMEOUT = 60
      
     # asynchron calls
     def self.call4JobId(url, apiKey, params)
       apiCallPayload = nil
       begin
         apiCallPayload = self.call(url, apiKey, params)['return']
       rescue ArgumentError => e
         raise ConfigError, e.message
       end
       if !apiCallPayload.is_a?(Hash)
         raise VagrantPlugins::Filoo::Errors::FilooApiError,
           code: 500,
           message: 'Unexpected return value to Api Call POST ' +  url + ' ' + params.to_json,
             description: 'Return value ' + apiCallPayload.to_json + ' is no a hash'
       end
       if apiCallPayload['jobid'].nil?
         raise VagrantPlugins::Filoo::Errors::FilooApiError,
           code: 500,
           message: 'Unexpected return value to Api Call POST ' +  url + ' ' + params.to_json,
             description: 'Return value ' + apiCallPayload.to_json + ' has no field "jobid"'
       end
       apiCallPayload['jobid']          
     end
 
 
     def self.waitJobDone(jobId, baseUrl, apiKey, timeout)
       timeout = timeout.nil? ? DEFAULT_TIMEOUT : timeout
       startTimeStamp = Time.now.to_f
       result = nil;
       while (result = requestJobStatusWithResult(jobId, baseUrl, apiKey)).nil?
         if startTimeStamp - Time.now.to_f > timeout
           raise Errors::FilooJobResultTimeoutError,
             job_id: jobId,
             timeout: timeout
         end
         sleep 3
       end
       result
     end
 
     def self.requestJobStatusWithResult(jobId, baseUrl, apiKey)
       url = baseUrl + SHOWJOB_RESOURCE
       params =  {:jobid => jobId}
       resp = nil
       begin
         resp = self.call(url, apiKey, {:jobid => jobId})
       rescue ArgumentError => e
         raise ConfigError, e.message
       end
       if resp['status']['description'] == "jobID not found"
         raise VagrantPlugins::Filoo::Errors::FilooApiError,
           code: 500,
           message: "Unexpected return value to Api Call POST " +  url + " " + {:jobid => jobId}.to_json,
             code: 500,
             description: "Requested jobid #{jobId} not found",
             jobid: jobid
       end
       returnVal = resp['return']
       if !returnVal.is_a?(Hash)
         raise VagrantPlugins::Filoo::Errors::FilooApiError,
           code: 500,
           message: "Unexpected return value to Api Call POST " +  url + " " + {:jobid => jobId}.to_json,
             description: "Return value " + returnVal.to_json + " is not a Hash" 
       end
       if returnVal['job_status'].nil?
         raise VagrantPlugins::Filoo::Errors::FilooApiError,
           code: 500,
           message: "Unexpected return value to Api Call POST " +  url + " " + {:jobid => jobId}.to_json,
           description: 'JSON response ' + returnVal.to_json + ' has no Field "job_status"' 
       end
       if returnVal['jobid'] != jobId
         raise VagrantPlugins::Filoo::Errors::FilooApiError,
           code: 500,
           message: "Unexpected return value to Api Call POST " +  url + " " + {:jobid => jobId}.to_json,
           description: "Response references wrong jobid #{returnVal['jobid']} must refernce #{jobId}. Response: " + resp.to_json
       end
       if returnVal['job_param'].nil?
         raise VagrantPlugins::Filoo::Errors::FilooApiError,
           code: 500,
           message: "Unexpected return value to Api Call POST " +  url + " #{params} " + {:jobid => jobId}.to_json,
             description: "Response has no field job_param in result. Response:  " + returnVal.to_json
       end
       LOGGER.info("Filoo Job #{resp['return']['job_command']} #{resp['return']['job_status_text']}")
       case returnVal['job_status_text']
         when 'finished'
           jobResult = nil
           if !returnVal['job_result'].nil? and returnVal['job_result'] != ""
             jobResult = JSON.parse(returnVal['job_result'])
           end
           return   {:result => jobResult, :status => 'finished', jobid: jobId, job_command: returnVal['job_command'], job_param: returnVal['job_param']}
         when 'failed', 'aborted'
           raise VagrantPlugins::Filoo::Errors::FilooJobFailedError,
             jobid: returnVal['jobid'],
             job_command: returnVal['job_command'],
             job_param: returnVal['job_param'],
             message: "Job Execution Failed for Task #{returnVal['job_command']} with parameters #{returnVal['job_param']} and Job Id #{returnVal['jobid']}:" + resp.to_json
         when 'new', 'processing'
           return nil
       end
     end
 
     # synchron call
     def self.call(url, apiKey, params)
       resp = doHttpCall(url, params, apiKey)
       jsonResp = nil
       begin
         jsonResp = JSON.parse(resp.body)
       rescue JSON::ParserError => e
         raise VagrantPlugins::Filoo::Errors::FilooApiError, 
           code: 500,
           message: "Can not parse JSON from response to POST " + url + " " + params.to_json,
           description: "Can not parse  " + resp.body + ": " + e.message
       end
       if  !jsonResp['return'].nil?
         return jsonResp
       else
         raise VagrantPlugins::Filoo::Errors::FilooApiError,
           code: 500,
           message: "No return field in response to POST " + url + " " + params.to_json,
           description: "Response from api " + resp.body
       end 
       return jsonResp
     end

     #http handling
     def self.doHttpCall(url, params, apiKey)
       if apiKey.nil? or apiKey == ""
         raise ArgumentError, "filoo.filoo_api_key must be set"
       end
       if !(url =~ URI::regexp)
         raise ArgumentError, "url must be a valid http resource but is #{url}"
       end

       boundary = createBoundary
       headers = { Authorization:  apiKey, :content_type => "multipart/form-data; boundary=----#{boundary}"}
       body = createBody(params, boundary)
       resp = nil
       begin
         resp = RestClient.post url, body, headers
         rescue RestClient::BadRequest => e
           raise VagrantPlugins::Filoo::Errors::FilooApiError,
             code: e.http_code,
             message: "Wrong parameter set #{params.to_json} on call to #{url}",
             description: e.http_body
   
         rescue RestClient::Unauthorized => e
           raise VagrantPlugins::Filoo::Errors::FilooApiError,
             code: e.http_code,
             message: "Can not Authenticate with Api Key",
             description: e.http_body
                 
         rescue RestClient::Forbidden => e
           raise VagrantPlugins::Filoo::Errors::FilooApiError,
             code: e.http_code,
             message: "No Access granted on call to #{url} using parameters #{params.to_json}",
             description: e.http_body

         rescue RestClient::NotAcceptable => e
           raise VagrantPlugins::Filoo::Errors::FilooApiError,
             code: e.http_code,
             message: "Async task triggered by call to #{url} using parameters #{params.to_json} is yet in queue",
             description: e.http_body    
             
         rescue RestClient::RequestFailed => e
           raise VagrantPlugins::Filoo::Errors::VagrantFilooError,
             message: e.message
             code -1
       end

       if resp.code != 200
         raise VagrantPlugins::Filoo::Errors::FilooApiError, 
            code: jsonResp['status']['code'],
            message: jsonResp['status']['message'],
            description: jsonResp['status']['description']
       end

       return resp
     end

     def self.createBody(params, boundary)
       body = ""
       params.each do |name, value|
         body = body + createPartFromParam(name, value, "------" + boundary)
       end
       body + "------" + boundary +"--"
     end

     def self.createPartFromParam(name, value, boundary)
        "#{boundary}\nContent-Disposition: form-data; name=\"#{name}\"\n\n#{value}\n"
     end

     def self.createBoundary
       random = ""; 16.times{random << ((rand(2)==1?65:97) + rand(25)).chr}
       "VagrantFilooHttpClient#{random}"
     end

    end
  end
end