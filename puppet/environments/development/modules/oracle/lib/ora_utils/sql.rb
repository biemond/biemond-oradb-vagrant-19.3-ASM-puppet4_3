require 'tempfile'
require 'fileutils'
require 'ora_utils/ora_daemon'
require 'ora_utils/ora_direct'
require 'ora_utils/ora_tab'

module OraUtils
  class Sql


    OS_USER_NAME = 'ORA_OS_USER'

    VALID_OPTIONS = [
      :sid,
      :os_user,
      :password,
      :timeout,
      :daemonized,
      :username,
    ]

    def initialize(options = {})
      check_options(options)
      @sid         = options.fetch(:sid) { raise ArgumentError, "SID must be present"}
      @os_user     = options.fetch(:os_user) { default_ora_user}
      @username    = options.fetch(:username) { 'sysdba'}
      @password    = options[:password] # null allowed
      @timeout     = options[:timeout]
      @daemonized  = options.fetch(:daemonized) { true}  # Default use daemonized because it's faster
      if @daemonized
        @executor = OraDaemon.run(@os_user, @sid, @username, @password)
      else
        @executor = OraDirect.run(@os_user, @sid, @username, @password)
      end
      validate_sid
    end

    def execute(command)
      create_output_file
      if @timeout
        @executor.execute_sql_command(command, @output_file.path, timeout)
      else
        @executor.execute_sql_command(command, @output_file.path)
      end
    end

    private

    def create_output_file
      @output_file = Tempfile.new([ 'output', '.csv' ])
      @output_file.close
      FileUtils.chown(@os_user, nil, @output_file.path)
      FileUtils.chmod(0644, @output_file.path)
      @output_file.close
      FileUtils.chown(@os_user, nil, @output_file.path)
      FileUtils.chmod(0644, @output_file.path)
    end


    def validate_sid
      oratab = OraUtils::OraTab.new
      raise ArgumentError, "sid #{@sid} doesn't exist on node" unless oratab.valid_sid?(@sid) 
    end

    def check_options(options)
      options.each_key {| key|  raise ArgumentError, "option #{key} invalid for sql" unless VALID_OPTIONS.include?(key)}
    end


    def default_ora_user
      ENV[OS_USER_NAME] ||  Facter.value('OS_USER_NAME') || 'oracle'
    end

  end
end