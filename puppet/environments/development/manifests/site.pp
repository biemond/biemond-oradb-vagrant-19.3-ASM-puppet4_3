node 'dbasm.example.com' {
  include oradb_asm_os
  include nfs_defintion
  include oradb_asm
}

Package{allow_virtual => false,}

# operating settings for Database & Middleware
class oradb_asm_os {

  # swap_file::files { 'swap_file':
  #   ensure       => present,
  #   swapfilesize => '8 GB',
  #   swapfile     => '/data/swap.1' 
  # }

  # set the tmpfs
  mount { '/dev/shm':
    ensure      => present,
    atboot      => true,
    device      => 'tmpfs',
    fstype      => 'tmpfs',
    options     => 'size=2000m',
  }

  $host_instances = hiera('hosts', {})
  create_resources('host',$host_instances)

  service { iptables:
    enable    => false,
    ensure    => false,
    hasstatus => true,
  }

  $all_groups = ['oinstall','dba' ,'oper','asmdba','asmadmin','asmoper']

  group { $all_groups :
    ensure      => present,
  }

  user { 'oracle' :
    ensure      => present,
    uid         => 500,
    gid         => 'oinstall',
    groups      => ['oinstall','dba','oper','asmdba'],
    shell       => '/bin/bash',
    password    => '$1$DSJ51vh6$4XzzwyIOk6Bi/54kglGk3.',
    home        => '/home/oracle',
    comment     => 'This user oracle was created by Puppet',
    require     => Group[$all_groups],
    managehome  => true,
  }

  user { 'grid' :
    ensure      => present,
    uid         => 501,
    gid         => 'oinstall',
    groups      => ['oinstall','dba','asmadmin','asmdba','asmoper'],
    shell       => '/bin/bash',
    password    => '$1$DSJ51vh6$4XzzwyIOk6Bi/54kglGk3.',
    home        => '/home/grid',
    comment     => 'This user grid was created by Puppet',
    require     => Group[$all_groups],
    managehome  => true,
  }


  $install = ['binutils.x86_64', 'compat-libstdc++-33.x86_64', 'glibc.x86_64',
              'ksh.x86_64','libaio.x86_64',
              'libgcc.x86_64', 'libstdc++.x86_64', 'make.x86_64',
              'compat-libcap1.x86_64', 'gcc.x86_64',
              'gcc-c++.x86_64','glibc-devel.x86_64','libaio-devel.x86_64',
              'libstdc++-devel.x86_64',
              'sysstat.x86_64','unixODBC-devel','glibc.i686','libXext.x86_64',
              'libXtst.x86_64','xorg-x11-xauth.x86_64',
              'elfutils-libelf-devel','kernel-debug','psmisc']


  package { $install:
    ensure  => present,
  }

  class { 'limits':
    config => {
                '*'       => { 'nofile'  => { soft => '2048'   , hard => '8192',   },},
                'oracle'  => { 'nofile'  => { soft => '65536'  , hard => '65536',  },
                                'nproc'  => { soft => '2048'   , hard => '16384',  },
                                'stack'  => { soft => '16384'  , hard => '16384',  },},
                'grid'    => { 'nofile'  => { soft => '65536'  , hard => '65536',  },
                                'nproc'  => { soft => '16384'  , hard => '16384',  },
                                'stack'  => { soft => '10240'  , hard => '32768',  },},
                },
    use_hiera => false,
  }

  sysctl { 'kernel.msgmnb':                 ensure => 'present', permanent => 'yes', value => '65536',}
  sysctl { 'kernel.msgmax':                 ensure => 'present', permanent => 'yes', value => '65536',}
  sysctl { 'kernel.shmmax':                 ensure => 'present', permanent => 'yes', value => '4398046511104',}
  sysctl { 'kernel.shmall':                 ensure => 'present', permanent => 'yes', value => '1073741824',}
  sysctl { 'fs.file-max':                   ensure => 'present', permanent => 'yes', value => '6815744',}
  sysctl { 'net.ipv4.tcp_keepalive_time':   ensure => 'present', permanent => 'yes', value => '1800',}
  sysctl { 'net.ipv4.tcp_keepalive_intvl':  ensure => 'present', permanent => 'yes', value => '30',}
  sysctl { 'net.ipv4.tcp_keepalive_probes': ensure => 'present', permanent => 'yes', value => '5',}
  sysctl { 'net.ipv4.tcp_fin_timeout':      ensure => 'present', permanent => 'yes', value => '30',}
  sysctl { 'kernel.shmmni':                 ensure => 'present', permanent => 'yes', value => '4096', }
  sysctl { 'fs.aio-max-nr':                 ensure => 'present', permanent => 'yes', value => '1048576',}
  sysctl { 'kernel.sem':                    ensure => 'present', permanent => 'yes', value => '250 32000 100 128',}
  sysctl { 'net.ipv4.ip_local_port_range':  ensure => 'present', permanent => 'yes', value => '9000 65500',}
  sysctl { 'net.core.rmem_default':         ensure => 'present', permanent => 'yes', value => '262144',}
  sysctl { 'net.core.rmem_max':             ensure => 'present', permanent => 'yes', value => '4194304', }
  sysctl { 'net.core.wmem_default':         ensure => 'present', permanent => 'yes', value => '262144',}
  sysctl { 'net.core.wmem_max':             ensure => 'present', permanent => 'yes', value => '1048576',}

}

class nfs_defintion {
  require oradb_asm_os

  file { '/home/nfs_server_data':
    ensure  => directory,
    recurse => false,
    replace => false,
    mode    => '0775',
    owner   => 'grid',
    group   => 'asmadmin',
    require =>  User['grid'],
  }

  class { '::nfs':
    server_enabled => true,
    client_enabled => true,
  }

  nfs::server::export{ '/home/nfs_server_data':
    ensure      => 'mounted',
    options_nfs => 'rw sync no_wdelay insecure_locks no_root_squash',
    clients     => '10.10.10.0/24(rw,insecure,async,no_root_squash) localhost(rw)',
    require     => [File['/home/nfs_server_data'],Class['nfs'],],
  }

  # class { 'nfs::server':
  #   package => latest,
  #   service => running,
  #   enable  => true,
  # }

  # nfs::export { '/home/nfs_server_data':
  #   options => [ 'rw', 'sync', 'no_wdelay','insecure_locks','no_root_squash' ],
  #   clients => [ '*' ],
  #   require => [File['/home/nfs_server_data'],Class['nfs::server'],],
  # }

  file { '/nfs_client':
    ensure  => directory,
    recurse => false,
    replace => false,
    mode    => '0775',
    owner   => 'grid',
    group   => 'asmadmin',
    require =>  User['grid'],
  }

  nfs::client::mount { '/nfs_client':
    server        => 'dbasm',
    share         => '/home/nfs_server_data',
    remounts      => true,
    atboot        => true,
    options_nfs   => 'rw,bg,hard,nointr,tcp,vers=3,timeo=600,rsize=32768,wsize=32768',
    require       => [File['/nfs_client'],Nfs::Server::Export['/home/nfs_server_data'],]
  }

  # mounts { 'Mount point for NFS data':
  #   ensure  => present,
  #   source  => 'dbasm:/home/nfs_server_data',
  #   dest    => '/nfs_client',
  #   type    => 'nfs',
  #   opts    => 'rw,bg,hard,nointr,tcp,vers=3,timeo=600,rsize=32768,wsize=32768,actimeo=0  0 0',
  #   require => [File['/nfs_client'],Nfs::Export['/home/nfs_server_data'],]
  # }

  exec { '/bin/dd if=/dev/zero of=/nfs_client/asm_sda_nfs_b1 bs=1M count=7520':
    user      => 'grid',
    group     => 'asmadmin',
    logoutput => true,
    unless    => '/usr/bin/test -f /nfs_client/asm_sda_nfs_b1',
    require   => Nfs::Client::Mount['/nfs_client'],
  }
  exec { '/bin/dd if=/dev/zero of=/nfs_client/asm_sda_nfs_b2 bs=1M count=7520':
    user      => 'grid',
    group     => 'asmadmin',
    logoutput => true,
    unless    => '/usr/bin/test -f /nfs_client/asm_sda_nfs_b2',
    require   => [Nfs::Client::Mount['/nfs_client'],
                  Exec['/bin/dd if=/dev/zero of=/nfs_client/asm_sda_nfs_b1 bs=1M count=7520']],
  }

  exec { '/bin/dd if=/dev/zero of=/nfs_client/asm_sda_nfs_b3 bs=1M count=7520':
    user      => 'grid',
    group     => 'asmadmin',
    logoutput => true,
    unless    => '/usr/bin/test -f /nfs_client/asm_sda_nfs_b3',
    require   => [Nfs::Client::Mount['/nfs_client'],
                  Exec['/bin/dd if=/dev/zero of=/nfs_client/asm_sda_nfs_b1 bs=1M count=7520'],
                  Exec['/bin/dd if=/dev/zero of=/nfs_client/asm_sda_nfs_b2 bs=1M count=7520'],],
  }

  exec { '/bin/dd if=/dev/zero of=/nfs_client/asm_sda_nfs_b4 bs=1M count=7520':
    user      => 'grid',
    group     => 'asmadmin',
    logoutput => true,
    unless    => '/usr/bin/test -f /nfs_client/asm_sda_nfs_b4',
    require   => [Nfs::Client::Mount['/nfs_client'],
                  Exec['/bin/dd if=/dev/zero of=/nfs_client/asm_sda_nfs_b1 bs=1M count=7520'],
                  Exec['/bin/dd if=/dev/zero of=/nfs_client/asm_sda_nfs_b2 bs=1M count=7520'],
                  Exec['/bin/dd if=/dev/zero of=/nfs_client/asm_sda_nfs_b3 bs=1M count=7520'],],
  }

  $nfs_files = ['/nfs_client/asm_sda_nfs_b1','/nfs_client/asm_sda_nfs_b2','/nfs_client/asm_sda_nfs_b3','/nfs_client/asm_sda_nfs_b4']

  file { $nfs_files:
    ensure  => present,
    owner   => 'grid',
    group   => 'asmadmin',
    mode    => '0664',
    require => Exec['/bin/dd if=/dev/zero of=/nfs_client/asm_sda_nfs_b4 bs=1M count=7520'],
  }
}

class oradb_asm {
  require oradb_asm_os, nfs_defintion

    oradb::installasm{ 'grid_linux-x64':
      version                => lookup('db_version'),
      file                   => lookup('asm_file'),
      grid_type              => 'HA_CONFIG',
      grid_base              => lookup('grid_base_dir'),
      grid_home              => lookup('grid_home_dir'),
      ora_inventory_dir      => lookup('oraInventory_dir'),
      user                   => lookup('grid_os_user'),
      asm_diskgroup          => 'DATA',
      disk_discovery_string  => '/nfs_client/asm*',
      disks                  => '/nfs_client/asm_sda_nfs_b1,/nfs_client/asm_sda_nfs_b2',
      disk_redundancy        => 'EXTERNAL',
      remote_file            => false,
      puppet_download_mnt_point => lookup('oracle_source'),
    }

    oradb::installdb{ 'db_linux-x64':
      version                => lookup('db_version'),
      file                   => lookup('db_file'),
      database_type          => 'EE',
      ora_inventory_dir      => lookup('oraInventory_dir'),
      oracle_base            => lookup('oracle_base_dir'),
      oracle_home            => lookup('oracle_home_dir'),
      user_base_dir          => '/home',
      user                   => lookup('oracle_os_user'),
      group                  => 'dba',
      group_install          => 'oinstall',
      group_oper             => 'oper',
      download_dir           => lookup('oracle_download_dir'),
      remote_file            => false,
      puppet_download_mnt_point => lookup('oracle_source'),
      require                   => Oradb::Installasm['grid_linux-x64'],
    }

    ora_asm_diskgroup{ 'RECO@+ASM':
      ensure          => 'present',
      au_size         => '1',
      compat_asm      => '12.1.0.0.0',
      compat_rdbms    => '12.1.0.0.0',
      diskgroup_state => 'MOUNTED',
      disks           => {'RECO_0000' => {'diskname' => 'RECO_0000', 'path' => '/nfs_client/asm_sda_nfs_b3'},
                          'RECO_0001' => {'diskname' => 'RECO_0001', 'path' => '/nfs_client/asm_sda_nfs_b4'}},
      redundancy_type => 'EXTERNAL',
      require         => Oradb::Installdb['db_linux-x64'],
    }

    oradb::database{ 'oraDb':
      oracle_base               => lookup('oracle_base_dir'),
      oracle_home               => lookup('oracle_home_dir'),
      version                   => lookup('dbinstance_version'),
      user                      => lookup('oracle_os_user'),
      group                     => lookup('oracle_os_group'),
      download_dir              => lookup('oracle_download_dir'),
      action                    => 'create',
      db_name                   => lookup('oracle_database_name'),
      db_domain                 => lookup('oracle_database_domain_name'),
      sys_password              => lookup('oracle_database_sys_password'),
      system_password           => lookup('oracle_database_system_password'),
      # template                  => 'dbtemplate_12.1_asm',
      character_set             => 'AL32UTF8',
      nationalcharacter_set     => 'UTF8',
      sample_schema             => 'false',
      memory_percentage         => 40,
      memory_total              => 2880,
      automatic_memory_management => false,
      database_type             => 'MULTIPURPOSE',
      em_configuration          => 'NONE',
      storage_type              => 'ASM',
      asm_snmp_password         => 'Welcome01',
      asm_diskgroup             => '+DATA/{DB_UNIQUE_NAME}',
      data_file_destination     => '+DATA/{DB_UNIQUE_NAME}',
      recovery_diskgroup        => '+RECO',
      recovery_area_destination => '+RECO',
      puppet_download_mnt_point => 'oradb/',
      require                   =>  Ora_asm_diskgroup['RECO@+ASM'],
    }

    oradb::dbactions{ 'start oraDb':
      oracle_home             => lookup('oracle_home_dir'),
      user                    => lookup('oracle_os_user'),
      group                   => lookup('oracle_os_group'),
      action                  => 'start',
      db_name                 => lookup('oracle_database_name'),
      require                 => Oradb::Database['oraDb'],
    }

    oradb::autostartdatabase{ 'autostart oracle':
      oracle_home             => lookup('oracle_home_dir'),
      user                    => lookup('oracle_os_user'),
      db_name                 => lookup('oracle_database_name'),
      require                 => Oradb::Dbactions['start oraDb'],
    }

}

