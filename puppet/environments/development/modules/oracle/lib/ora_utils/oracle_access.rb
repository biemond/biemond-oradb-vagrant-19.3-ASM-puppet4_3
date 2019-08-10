require 'tempfile'
require 'fileutils'
require 'ora_utils/sql'

module OraUtils
  module OracleAccess

    OS_USER_NAME = 'ASM_OS_USER'

    def self.included(parent)
      parent.extend(OracleAccess)
    end


    ##
    #
    # Use this function to execute Oracle statements on a set of specfied sids
    #
    # @param sids [Array] Array of SIDS
    # @param command [String] this is the commands to be given
    #
    #
    def sql_on( sids, command, parameters = {})
      results = []
      sids.each do |sid|
        results = results + sql(command, {:sid => sid}.merge(parameters))
      end
      results
    end

    ##
    #
    # Use this function to execute Oracle statements
    #
    # @param command [String] this is the commands to be given
    #
    #
    def sql_on_all_sids( command, parameters = {})
      results = []
      oratab = OraTab.new
      oratab.running_database_sids.each do |sid|
        results = results + sql(command, {:sid => sid}.merge(parameters))
      end
      results
    end


    ##
    #
    # Use this function to execute Oracle statements
    #
    # @param command [String] this is the commands to be given
    #
    #
    def sql( command, options = {})
      @sql ||= OraUtils::Sql.new(options)
      sid = options.fetch(:sid) { fail "SID must be present"}
      Puppet.debug "Executing: #{command} on database #{sid}"
      csv_string = execute_sql(command, options)
      add_sid_to(convert_csv_data_to_hash(csv_string, [], :converters=> lambda {|f| f ? f.strip : nil}),sid)
    end

    def execute_on_sid(sid, command_builder)
      command_builder.options.merge!(:sid => sid)
      nil
    end

    def execute_sql(command, options)
      @sql = OraUtils::Sql.new( options)
      @sql.execute(command)
    end


    def add_sid_to(elements, sid)
      elements.collect{|e| e['SID'] = sid; e}
    end

    # This is a little hack to get a specified timeout value
     def timeout_specified
      if respond_to?(:to_hash)
        to_hash.fetch(:timeout) { nil} #
      else
        nil
      end
    end

    def sid_from_resource
      oratab = OraUtils::OraTab.new
      resource.sid.empty? ? oratab.default_sid : resource.sid
    end

    private

    def default_asm_user
      ENV[OS_USER_NAME] ||  Facter.value(OS_USER_NAME) || 'grid'
    end


  end
end