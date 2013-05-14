# Internal: Prepare your system for MySQL.
#
# Examples
#
#   include mysql::params
class mysql::params(
  $bind_address = undef,
  $ensure       = undef,
  $port         = undef,
  $socket       = undef
) {
  case $::osfamily {
    'Darwin': {
      include boxen::config

      $configdir   = "${boxen::config::configdir}/mysql"
      $datadir     = "${boxen::config::datadir}/mysql"
      $logdir      = "${boxen::config::logdir}/mysql"
      $mysqladmin  = "${boxen::config::homebrewdir}/bin/mysqladmin"
      $mysqld_safe = "${boxen::config::homebrewdir}/bin/mysqld_safe"
      $service     = 'dev.mysql'
    }

    'Linux': {
      $configdir   = '/etc'
      $datadir     = '/var/lib/mysql'
      $logdir      = '/var/log/mysql'
      $mysqladmin  = '/usr/bin/mysqladmin'
      $mysqld_safe = '/usr/bin/mysqld_safe'
      $service     = 'mysql'
    }
  }

  $configfile   = "${configdir}/my.cnf"
  $logerror     = "${logdir}/error.log"
}
