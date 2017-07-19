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
      $manage_pam_support        = true
      $tac_plus_template_default = 'tacacsplus/tac_plus.conf.erb'
      $tac_plus_service          = 'tac_plus'
      $tac_plus_config           = '/etc/tac_plus.conf'
    }
    'Ubuntu': {
      $init_template             = undef # will also forbid using $manage_init_script, expect init script from package
      $manage_pam_support        = false
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

  if $manage_init_script == true {
    if $init_template != undef {
      file { '/etc/init.d/tac_plus':
        ensure  => 'file',
        content => template($init_template),
        owner   => 'root',
        group   => 'root',
        mode    => '0744',
        before  => Service['tacas_plus_service'],
      }
    } else {
      fail ('tacasplus::manage_init_script is not supported for this operating system.')
    }
  }

  # TODO: what about the mode?
  file { 'tacas_plus_config':
    ensure  => 'file',
    path    => $tac_plus_config,
    content => template($tac_plus_template_real),
    owner   => 'root',
    group   => 'root',
    require => Package[$tacplus_pkg],
    notify  => Service['tacas_plus_service'],
  }

  if $manage_pam == true {
    if $manage_pam_support == true {
      # TODO: can/should we use the pam module to manage this?
      # TODO: What about the mode?
      file { '/etc/pam.d/tac_plus':
        ensure  => 'file',
        content => template('tacacsplus/tac_plus.erb'),
        owner   => 'root',
        group   => 'root',
        require => Package[$tacplus_pkg],
        before  => Service['tacas_plus_service'],
      }
    } else {
      fail ('tacasplus::manage_pam is not supported for this operating system.')
    }
  }

  service { 'tacas_plus_service':
    ensure    => 'running',
    name      => $tac_plus_service,
    enable    => true,
    hasstatus => false,
    pattern   => $tac_plus_service,
  }
}
