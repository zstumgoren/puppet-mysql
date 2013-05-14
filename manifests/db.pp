# Public: Create MySQL Databases
#
# namevar - The name of the database.
#
# Examples
#
#   mysql::db { 'foo': }
define mysql::db($ensure = present) {
  require mysql

  if $ensure == 'present' {
    exec { "create mysql db ${name}":
      command => "${mysql::mysqladmin} -uroot create ${name}",
      creates => "${mysql::datadir}/${name}",
      require => Exec['wait-for-mysql']
    }
  } elsif $ensure == 'absent' {
    exec { "delete mysql db ${name}":
      command => "${mysql::mysqladmin} -uroot drop database ${name}",
      require => Exec['wait-for-mysql']
    }
  }
}
