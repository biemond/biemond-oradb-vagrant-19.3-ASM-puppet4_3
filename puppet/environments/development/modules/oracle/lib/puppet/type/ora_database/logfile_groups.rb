# encoding: UTF-8
newparam(:logfile_groups, :array_matching => :all) do
  include EasyType
  
  desc 'One or more files to be used as redo log files.'
  
  #
  # Logfile groups are passed as a Hash
  # 1 => /logfile_1.log
  # 2 => /logfile_2.log
  # 3 => /logfile_3.log
  #
  to_translate_to_resource do | raw_resource|
  #  raw_resource.column_data('logfile_groups')
  end
      
  on_apply do | command_builder | 
    "LOGFILE GROUP #{groups}"
  end

  private

  def groups
    value.to_a.collect {|e| "#{e[0]} #{e[1]}"}.join(', ')
  end

end