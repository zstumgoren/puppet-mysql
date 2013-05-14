# Public: Install MySQL
#
# Examples
#
#   include mysql
class mysql(
  $bind_address = $mysql::params::bind_address,
  $configfile   = $mysql::params::configfile,
  $datadir      = $mysql::params::datadir,
  $ensure       = 'present',
  $logdir       = $mysql::params::logdir,
  $logerror     = $mysql::params::logerror,
  $mysqladmin   = $mysql::params::mysqladmin,
  $mysqld_safe  = $mysql::params::mysqld,
  $port         = $mysql::params::port,
  $socket       = $mysql::params::socket,
) inherits mysql::params {

  file {
    [
      $mysql::params::configdir,
      $mysql::datadir,
      $mysql::params::logdir
    ]:
      ensure => directory ;
    $mysql::params::configfile:
      content => template('mysql/my.cnf.erb'),
      notify  => Service['mysql'] ;
  }

  package { 'mysql':
    ensure => $mysql::ensure,
    name   => $mysql::params::package,
    notify => Service['mysql']
  }

  service { 'mysql':
    ensure  => running,
    name    => $mysql::params::service,
    notify  => Exec['wait-for-mysql'],
  }

  case $::osfamily {
    'Darwin': {
      require homebrew

      file { "${boxen::config::homebrewdir}/etc/my.cnf":
        ensure  => link,
        require => [
          Package['mysql'],
          File[$mysql::params::configfile],
          Class['homebrew']
        ],
        target  => $mysql::params::configfile,
      }

      file { '/Library/LaunchDaemons/mysql.plist':
        content => template('mysql/dev.mysql.plist.erb'),
        group   => 'wheel',
        notify  => Service['mysql'],
        owner   => 'root'
      }

      homebrew::formula { 'mysql':
        before => Package['mysql'],
      }

      file { "${boxen::config::homebrewdir}/var/mysql":
        ensure  => absent,
        force   => true,
        recurse => true,
        require => Package['mysql'],
      }

      exec { 'init-mysql-db':
        command  => "mysql_install_db \
          --verbose \
          --basedir=${boxen::config::homebrewdir} \
          --datadir=${mysql::datadir} \
          --tmpdir=/tmp",
        creates  => "${mysql::datadir}/mysql",
        provider => shell,
        require  => [
          Package['mysql'],
          File["${boxen::config::homebrewdir}/var/mysql"]
        ],
        notify   => Service['mysql']
      }
    }
  }

  $nc = "/usr/bin/nc -z ${mysql::bind_address} ${mysql::port}"

  exec { 'wait-for-mysql':
    command     => "while ! ${nc}; do sleep 1; done",
    provider    => shell,
    timeout     => 30,
    refreshonly => true
  }

  exec { 'mysql-tzinfo-to-sql':
    command     => "mysql_tzinfo_to_sql /usr/share/zoneinfo | \
      mysql -u root mysql -P ${mysql::port} -S ${mysql::socket}",
    provider    => shell,
    creates     => "${mysql::datadir}/.tz_info_created",
    subscribe   => Exec['wait-for-mysql'],
    refreshonly => true
  }
}
