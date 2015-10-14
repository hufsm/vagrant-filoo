require "vagrant"

module VagrantPlugins
  module Filoo
    class Config < Vagrant.plugin("2", :config)
      # The access key ID for accessing Filoo.
      #
      # @return [String]
      attr_accessor :filoo_api_key
      attr_accessor :filoo_api_entry_point
      attr_accessor :filoo_api_entry_point
      
      attr_accessor :cd_image_name
      attr_accessor :type
      attr_accessor :cpu
      attr_accessor :ram
      attr_accessor :hdd

      
      
      def initialize()
        @filoo_api_key             = nil
        @filoo_api_entry_point      = nil
        @cd_image_name      = nil
        @type      = nil
        @cpu      = nil
        @ram      = nil
        @hdd      = nil
      end
      
      # set security_groups
      def security_groups=(value)
        # convert value to array if necessary
        @security_groups = value.is_a?(Array) ? value : [value]
      end
      
      
      def finalize!
        # Try to get access keys from standard FILOO environment variables; they
        # will default to nil if the environment variables are not present.
         @filoo_api_key     = ENV['FILOO_API_KEY'] if @filoo_api_key     == nil
         @filoo_api_entry_point =  ENV['FILOO_API_ENTRY_POINT'] if @filoo_api_entry_point  == nil
           
         #set default values for machine
         @cd_image_name =  'Debian 7.7 - 64bit' if @cd_image_name  == nil
         @type = 'dynamic' if @type  == nil
         @cpu = 1 if @cpu  == nil
         @ram = 128 if @ram  == nil
         @hdd = 10 if @hdd  == nil   
      end
    end
  end
end
