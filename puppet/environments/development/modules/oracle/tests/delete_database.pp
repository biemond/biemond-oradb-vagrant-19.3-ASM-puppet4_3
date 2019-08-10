ora_database{'bert':
  ensure        => absent,
  oracle_base   => '/opt/oracle',
  oracle_home   => '/opt/oracle/app/11.04',
  control_file  => 'reuse',
}
