ora_database{'bert':
  ensure            => present,
  oracle_base       => '/opt/oracle',
  oracle_home       => '/opt/oracle/app/11.04',
  control_file      => 'reuse',
  create_catalog    => 'no',
  extent_management => 'local',
  default_tablespace => {
    name      => 'USERS',
    datafile  => {
      file_name  => 'users.dbs',
      size       => '1G',
      reuse      =>  true,
    },
    extent_management => {
      type          => 'local',
      autoallocate  => true,
    }
  },
  datafiles       => [
    {file_name   => 'file1.dbs', size => '1G', reuse => true},
    {file_name   => 'file2.dbs', size => '1G', reuse => true},
  ],
  default_temporary_tablespace => {
    name      => 'TEMP',
    type      => 'bigfile',
    tempfile  => {
      file_name  => 'tmp.dbs',
      size       => '1G',
      reuse      =>  true,
    },
    extent_management => {
      type          => 'local',
      uniform_size  => '1G',
    },
  },
  undo_tablespace   => {
    name      => 'UNDOTBS1',
    type      => 'bigfile',
    datafile  => {
      file_name  => 'undo.dbs',
      size       => '1G',
      reuse      =>  true,
    }
  },
  sysaux_datafiles => [
    {file_name   => 'sysaux1.dbs', size => '1G', reuse => true},
    {file_name   => 'sysaux2.dbs', size => '1G', reuse => true},
  ]


}
