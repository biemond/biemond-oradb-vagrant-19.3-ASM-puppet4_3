require 'easy_type'

class OraDirect
  include EasyType::Template

  DEFAULT_TIMEOUT = 120 # 2 minutes

  attr_reader :user, :sid, :oraUser, :oraPassword

  def self.run(user, sid, oraUser='sysdba', oraPassword=nil, timeout = DEFAULT_TIMEOUT)
    self.new(user, sid, oraUser, oraPassword, timeout)
  end

  def initialize(user, sid, oraUser, oraPassword, timeout)
    @user        = user
    @sid         = sid
    @oraUser     = oraUser
    @oraPassword = oraPassword
  end

  def execute_sql_command(command, output_file, timeout = DEFAULT_TIMEOUT)
    Puppet.debug "Executing direct sql-command #{command}"
    script = command_file( template('puppet:///modules/oracle/shared/direct_execute.sql.erb', binding))
    os_command  = "su - #{user} -c 'export ORACLE_SID=#{@sid};export ORAENV_ASK=NO;. oraenv;sqlplus -S /nolog @#{script}'"
    Puppet::Util::Execution.execute(os_command, :failonfail => true)
    File.read(output_file)
  end

  private

  def command_file( content)
    command_file = Tempfile.new([ 'command', '.sql' ])
    command_file.write(content)
    FileUtils.chown(@user, nil, command_file.path)
    FileUtils.chmod(0644, command_file.path)
    command_file.close
    FileUtils.chown(@user, nil, command_file.path)
    FileUtils.chmod(0644, command_file.path)
    command_file.path
  end


end
