require 'fileutils'

Puppet::Type.type(:db_directory_structure).provide(:db_directory_structure) do
  def configure
    name            = resource[:name]
    oracle_base     = resource[:oracle_base_dir]
    oracle_home     = resource[:oracle_home_dir]
    ora_inventory   = resource[:ora_inventory_dir]
    download_folder = resource[:download_dir]
    user            = resource[:os_user]
    group           = resource[:os_group]
    Puppet.info "configure oracle folders for #{name}"

    Puppet.info "create the following directories: #{oracle_base}, #{ora_inventory}, #{download_folder}"
    make_directory oracle_base
    make_directory download_folder
    make_directory ora_inventory

    owned_by_oracle oracle_base, user, group
    allow_everybody download_folder, user, group
    owned_by_oracle ora_inventory, user, group

    unless oracle_home.nil?
      make_directory oracle_home
      owned_by_oracle oracle_home, user, group
    end
  end

  def make_directory(path)
    Puppet.info "creating directory #{path}"
    FileUtils.mkdir_p path
  end

  def owned_by_oracle(path, user, group)
    Puppet.info "Setting oracle ownership for #{path} with 0775"
    FileUtils.chmod 0775, path
    FileUtils.chown user, group, path
  end

  def allow_everybody(path, user, group)
    Puppet.info "Setting public permissions 0777 for #{path}"
    FileUtils.chmod 0777, path
    FileUtils.chown user, group, path
  end
end
