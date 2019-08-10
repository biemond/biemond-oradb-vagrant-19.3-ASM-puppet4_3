# encoding: UTF-8
newparam(:timezone) do
  include EasyType
  desc 'Set the time zone of the database.'
  
  to_translate_to_resource do | raw_resource|
  #  raw_resource.column_data('timezone')
  end

  on_apply do | command_builder| 
    "set time_zone = '#{value}'"
  end
  
end