#
# Tacacsplus class to handle the shrubbery.net tac_plus daemon
# http://www.shrubbery.net/tac_plus
#


class tacacsplus (
    $tacplus_pkg        = "tacacs+-F4.0.4.26-1",
) {

    if $operatingsystem =~ /RedHat|CentOS/ {
        package { $tacplus_pkg :
            ensure => installed,
        }
    } else {
        fail ("Operating system not supported")
    }

    file { "/etc/tac_plus.conf" :
        notify  => Service["tac_plus"],
        owner   => root,
        group   => root,
        require => Package[$tacplus_pkg],
#        content => template("tacacsplus/tac_plus.conf.erb"),
    }

    file { "/etc/pam.d/tac_plus" :
        owner   => root,
        group   => root,
        require => Package[$tacplus_pkg],
        content => template("tacacsplus/tac_plus.erb"),
     }

    service { "tac_plus" :
        enable => true,
        ensure => running,
        require => File['/etc/tac_plus.conf', '/etc/pam.d/tac_plus'],
    }
}
