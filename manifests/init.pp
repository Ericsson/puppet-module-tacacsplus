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

  # preparations
  case $::operatingsystem {
    'RedHat': {
      $init_template             = 'tacacsplus/tac_plus-redhat-init.erb'
      $tac_plus_template_default = 'tacacsplus/tac_plus.conf.erb'
      $tac_plus_service          = 'tac_plus'
      $tac_plus_config           = '/etc/tac_plus.conf'
    }
    'Ubuntu': {
      $init_template             = undef # Default init template for Ubuntu 16 from installer
      $tac_plus_template_default = 'tacacsplus/tac_plus.conf.erb'
      $tac_plus_service          = 'tacacs_plus'
      $tac_plus_config           = '/etc/tacacs+/tac_plus.conf'
    }
    default: {
      fail ('Operating system not supported')
    }
  }

  if $tac_plus_template == undef {
    $tac_plus_template_real = $tac_plus_template_default
  } else {
    $tac_plus_template_real = $tac_plus_template
  }

  $manage_init_script_bool = str2bool($manage_init_script)
  $manage_pam_bool = str2bool($manage_pam)

  # validations
  validate_bool(
    $manage_init_script_bool,
    $manage_pam_bool,
  )

  validate_hash(
    $acl,
    $groups,
    $localusers,
    $users,
  )

  validate_string(
    $default_group,
    $default_group_default_service,
    $default_group_login,
    $default_group_pap,
    $key,
    $tacplus_pkg,
    $tac_plus_template_real,
  )

  # functionality
  package { $tacplus_pkg:
    ensure => 'installed',
  }

  # Don't manage init script for Ubuntu
  if ($manage_init_script == true) and ($::operatingsystem != 'Ubuntu') {
    file { '/etc/init.d/tac_plus':
      ensure  => 'file',
      content => template($init_template),
      owner   => 'root',
      group   => 'root',
      mode    => '0744',
      before  => Service[$tac_plus_service],
    }
  }

  # TODO: what about the mode?
  file { $tac_plus_config:
    ensure  => 'file',
    content => template($tac_plus_template_real),
    owner   => 'root',
    group   => 'root',
    require => Package[$tacplus_pkg],
    notify  => Service[$tac_plus_service],
  }

  # PAM not supported on Ubuntu
  if ($manage_pam == true) and ($::operatingsystem != 'Ubuntu') {
    # TODO: can/should we use the pam module to manage this?
    # TODO: What about the mode?
    file { '/etc/pam.d/tac_plus':
      ensure  => 'file',
      content => template('tacacsplus/tac_plus.erb'),
      owner   => 'root',
      group   => 'root',
      require => Package[$tacplus_pkg],
      before  => Service[$tac_plus_service],
    }
  }

  service { $tac_plus_service:
    ensure    => 'running',
    enable    => true,
    hasstatus => false,
    pattern   => $tac_plus_service,
  }
}
