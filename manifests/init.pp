# == Class: tacacsplus
#
# Tacacsplus class to handle the shrubbery.net tac_plus daemon
# http://www.shrubbery.net/tac_plus
#
class tacacsplus (
  $tacplus_pkg   = 'tacacs+',
  $users         = 'NONE',
  $localusers    = 'NONE',
  $tac_key       = 'CHANGEME',
  $default_group = 'all_access',
) {

  case $::osfamily {
    'RedHat': {

      $init_template = 'tacacsplus/tac_plus-redhat-init.erb'

      package { $tacplus_pkg:
        ensure => installed,
      }
    }
    default: {
      fail ('Operating system not supported')
    }
  }

  file { '/etc/init.d/tac_plus':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0744',
    content => template($init_template)
  }

  file { '/etc/tac_plus.conf':
    ensure  => present,
    notify  => Service['tac_plus'],
    owner   => 'root',
    group   => 'root',
    require => Package[$tacplus_pkg],
    content => template('tacacsplus/tac_plus.conf.erb'),
  }

  file { '/etc/pam.d/tac_plus':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    require => Package[$tacplus_pkg],
    content => template('tacacsplus/tac_plus.erb'),
  }

  service { 'tac_plus':
    ensure    => running,
    enable    => true,
    hasstatus => false,
    pattern   => 'tac_plus',
    require   => [ File['/etc/tac_plus.conf'],
                    File['/etc/pam.d/tac_plus'],
                    File['/etc/init.d/tac_plus'],
                  ],
  }
}
