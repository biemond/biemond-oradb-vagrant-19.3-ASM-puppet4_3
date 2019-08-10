require 'ora_utils/oracle_access'
require 'easy_type'

Puppet::Type.type(:ora_database).provide(:nonprefetching) do
  include EasyType::Provider
  include ::OraUtils::OracleAccess

  desc "Manage an Oracle Database"

  mk_resource_methods

  self.instance_eval { undef :prefetch }

  def exists?
    available_databases.include?(resource.name)
  end

  private

  def available_databases
    Pathname.glob("#{resource.oracle_base}/admin/*").collect {|e| e.basename.to_s}
  end

end
