require "pathname"
require "vagrant/action/builder"
require_relative "action/create_server"
require_relative "action/get_images"
require_relative "action/read_state"
require_relative "action/stop_instance"
require_relative "action/terminate_instance"
require_relative "action/read_ssh_info"

module VagrantPlugins
  module Filoo
    module Action
      
      # This action is called to read the SSH info of the machine. The
      # resulting state is expected to be put into the `:machine_ssh_info`
      # key.
      def self.action_read_ssh_info
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ReadSSHInfo
        end
      end
      
      # This action is called to halt the remote machine.
      def self.action_halt
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use MessageNotCreated
              next
            end
            b2.use StopInstance
          end
        end
      end
      
      # This action is called to terminate the remote machine.
      def self.action_destroy
        Vagrant::Action::Builder.new.tap do |b|
          b.use Call, DestroyConfirm do |env, b2|
            if env[:result]
              b2.use ConfigValidate
              b2.use Call, IsCreated do |env2, b3|
                if !env2[:result]
                  b3.use MessageNotCreated
                  next
                end
                b3.use TerminateInstance
                b3.use ProvisionerCleanup if defined?(ProvisionerCleanup)
              end
            else
              b2.use MessageWillNotDestroy
            end
          end
        end
      end
      
      # This action is called when `vagrant provision` is called.
      def self.action_provision
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use MessageNotCreated
              next
            end

            b2.use Provision
            b2.use SyncedFolders
          end
        end
      end

      
      # This action is called to bring the box up from nothing.
      include Vagrant::Action::Builtin
      def self.action_up
        Vagrant::Action::Builder.new.tap do |b|
          b.use HandleBox
          b.use ConfigValidate
          b.use BoxCheckOutdated
          b.use Call, IsCreated do |env1, b1|
            if env1[:result]
              b1.use Call, IsStopped do |env2, b2|
                if env2[:result]
                  b2.use StartInstance # restart this instance  
                else
                  b2.use MessageAlreadyCreated # TODO write a better message
                end
              end
            else
              b1.use action_prepare_boot do |env1, b1|
                if env1[:result]["vmstatus"] == "stopped"
                  b1.use StartInstance # launch a new instance
                  
                elseif env1[:result]["vmstatus"] != "running"
                  raise VagrantPlugins::Filoo::Errors::UnexpectedStateError,
                  resource: "/vserver/status",
                  state: {"vmstatus" => env1[:result]["vmstatus"]},
                  message: "Unexpected vmstatus after create Server done, vmstatus " + env1[:result]["vmstatus"],
                  description: "Server with vmid  #{env1[:result]['vmid']} should be running or stopped "
                  end
              end
            end
          end
        end
      end

      def self.action_prepare_boot
        Vagrant::Action::Builder.new.tap do |b|
          b.use Provision
          b.use SyncedFolders
          b.use GetImages
          b.use CreateServer 
        end
      end
      
      
      # This action is called to SSH into the machine.
      def self.action_ssh
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use MessageNotCreated
              next
            end

            b2.use SSHExec
          end
        end
      end
      
      
      def self.action_ssh_run
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use MessageNotCreated
              next
            end

            b2.use SSHRun
          end
        end
      end
      
      # This action is called to read the state of the machine. The
      # resulting state is expected to be put into the `:machine_state_id`
      # key.
      def self.action_read_state
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ReadState
        end
      end
      
      
      def self.action_reload
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use MessageNotCreated
              next
            end
            b2.use action_halt
            b2.use action_up
          end
        end
      end
      
      # The autoload farm
      action_root = Pathname.new(File.expand_path("../action", __FILE__))
      autoload :IsCreated, action_root.join("is_created")
      autoload :IsStopped, action_root.join("is_stopped")
      autoload :MessageAlreadyCreated, action_root.join("message_already_created")
      autoload :MessageNotCreated, action_root.join("message_not_created")
      autoload :PackageInstance, action_root.join("package_instance")
      autoload :StartInstance, action_root.join("start_instance")
      autoload :ReadState, action_root.join("read_state")
      #autoload :StopInstance, action_root.join("stop_instance")
      #autoload :TerminateInstance, action_root.join("terminate_instance")
    end
  end
end
