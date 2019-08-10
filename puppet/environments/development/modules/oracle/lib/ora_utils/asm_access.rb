require 'tempfile'
require 'fileutils'

module OraUtils
  module AsmAccess

    OS_USER_NAME = 'ASM_OS_USER'

    VALID_OPTIONS = [
      :sid,
      :os_user,
      :timeout,
    ]


    def self.included(parent)
      parent.extend(AsmAccess)
    end

    ##
    #
    # Use this function to execute asmcmd statements
    #
    # @param command [String] this is the commands to be given
    #
    #
    def asmcmd( command, options = {})
      check_options( options )
      Puppet.debug "Executing asmcmd command: #{command}"
      os_user = options.fetch(:os_user) { default_asm_user}
      sid     = options.fetch(:sid) { raise ArgumentError, "you need to specify a sid for asm access"}
      full_command = "export ORACLE_SID=#{sid};export ORAENV_ASK=NO;. oraenv; asmcmd #{command}"
      options = {:uid => os_user, :failonfail => true}
      Puppet::Util::Execution.execute(full_command, options)
    end

    private


    def validate_sid
      oratab = OraUtils::OraTab.new
      raise ArgumentError, "asm sid #{@sid} doesn't exist on node" unless oratab.valid_asm_sid?(@sid) 
    end

    def check_options(options)
      options.each_key {| key|  raise ArgumentError, "option #{key} invalid for asm" unless VALID_OPTIONS.include?(key)}
    end


    def default_asm_user
      ENV[OS_USER_NAME] ||  Facter.value(OS_USER_NAME) || 'grid'
    end

  end
end