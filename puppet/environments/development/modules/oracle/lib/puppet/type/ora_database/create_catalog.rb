# encoding: UTF-8
newparam(:create_catalog) do
  include EasyType

  newvalues(:yes, :no)
  defaultto :yes

  desc 'Run the catalog script and other create scripts'

end

def create_catalog?
  create_catalog == :yes
end
