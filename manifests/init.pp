# == Class: tacacsplus
#
# Tacacsplus class to handle the shrubbery.net tac_plus daemon
# http://www.shrubbery.net/tac_plus
#
class tacacsplus (
  $tacplus_pkg                   = 'tacacs+',
  $acl                           = {},
  $users                         = {},
  $groups                        = {},
  $localusers                    = {},
  $key                           = 'CHANGEME',
  $default_group                 = 'all_access',
  $default_group_login           = 'PAM',
  $default_group_pap             = 'PAM',
  $default_group_default_service = 'deny',
  $tac_plus_template             = undef,
  $manage_init_script            = false,
  $manage_pam                    = false,
) {

  case $::osfamily {
    default: {
      fail ('Operating system not supported')
    }
    'RedHat': {
      $init_template = 'tacacsplus/tac_plus-redhat-init.erb'
      $default_tac_plus_template = 'tacacsplus/tac_plus.conf.erb'
    }
  }

  if $tac_plus_template == undef {
    $tac_plus_template_real = $default_tac_plus_template
  } else {
    $tac_plus_template_real = $tac_plus_template
  }
  validate_string($tac_plus_template_real)

  package { $tacplus_pkg:
    ensure => 'installed',
  }

  if $manage_init_script == true {
    file { '/etc/init.d/tac_plus':
      ensure  => 'file',
      content => template($init_template),
      owner   => 'root',
      group   => 'root',
      mode    => '0744',
      before  => Service['tac_plus'],
    }
  }

  # TODO: what about the mode?
  file { '/etc/tac_plus.conf':
    ensure  => 'file',
    content => template($tac_plus_template_real),
    owner   => 'root',
    group   => 'root',
    require => Package[$tacplus_pkg],
    notify  => Service['tac_plus'],
  }

  if $manage_pam == true {
    # TODO: can/should we use the pam module to manage this?
    # TODO: What about the mode?
    file { '/etc/pam.d/tac_plus':
      ensure  => 'file',
      content => template('tacacsplus/tac_plus.erb'),
      owner   => 'root',
      group   => 'root',
      require => Package[$tacplus_pkg],
      before  => Service['tac_plus'],
    }
  }

  service { 'tac_plus':
    ensure    => 'running',
    enable    => true,
    hasstatus => false,
    pattern   => 'tac_plus',
  }
}
