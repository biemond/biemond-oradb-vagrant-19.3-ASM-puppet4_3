# encoding: UTF-8
newparam(:init_ora_content) do
  include EasyType

  desc 'The file containing the init.ora parameters. '

end

def init_ora_content
  self[:init_ora_content] ? self[:init_ora_content] :  template('puppet:///modules/oracle/ora_database/default_init_ora.erb', binding)
end
