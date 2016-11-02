# puppet-module-tacacsplus

# Module description

Manage TACAS+.

# Compatibility

This module is built for use with Puppet v3 (with and without the future
parser) and Puppet v4 on the following platforms and supports Ruby versions
1.8.7, 1.9.3, 2.0.0, 2.1.0 and 2.3.1.

 * EL 6

# Class Descriptions
## Class `tacacsplus`
### Parameters

---
#### acl (type: Hash)
Containing names of Access Control Lists (ACL) and their permission and regex
pairs to appear in the ACL section of tac_plus.conf. ACL rules will get sorted
by their names. If sequence does matter, you could use ascending numbers as
prefix for your rule names.

- *Default*: {}

##### Example:
```yaml
tacacsplus::acl:
  'acl_all_features':
    permit: '127.0.0.1'
    permit: '192.168.2.*'
    deny:   '192.168.0.*'
    deny:   '192.168.1.*'
  'acl_deny_only':
    deny:   '192.168.0.*'
  'acl_permit_only':
    permit: '*'
```

Will add these ACL rules in tac_plus.conf:
```
acl = "acl_all_features" {
    permit = 127.0.0.1
    permit = 192.168.2.*
    deny = 192.168.0.*
    deny = 192.168.1.*
}

acl = "acl_deny_only" {
    deny = 192.168.0.*
}

acl = "acl_permit_only" {
    permit = *
}
```
---
#### default_group (type: String)
Name of the group to be used for users specified via $users and $localusers
when member group is not explicitly set.

- *Default*: 'all_access'

---
#### default_group_default_service (string)
Name of the default service to be used for groups specified via $groups
when default_service is not explicitly set.

- *Default*: 'deny'

---
#### default_group_login (string)
Name of the default login to be used for groups specified via $groups
when login is not explicitly set.

- *Default*: 'PAM'

---
#### default_group_pap (string)
Name of the default pap to be used for groups specified via $groups
when pap is not explicitly set.

- *Default*: 'PAM'

---
#### groups (type: Hash)
Containing group definitions to appear in the group section of tac_plus.conf.
Group definitions will get sorted by their names.

Supported attributes:
- default service (type: String) to overrides $default_group_default_service
- login (type: String) to override $default_group_login
- pap (type: String) to override $default_group_pap
- acl (type: String)
- service (type: Array containing Hashes)

- *Default*: {}

##### Example:
```yaml
tacacsplus::groups:
  'using-default-settings-only':
  'overriding-default-settings':
    default_service:   'allow'
    login:             'skey'
    pap:               'des 0AmUKnIT2gheo'
  'other-features':
    acl: 'acl-name'
    service:
      service-name:
        -
          local-user-name: 'name'
          allow-commands:  '(show .*)|exit'
          deny-commands:   '.*'
```

Will add these groups in tac_plus.conf:
```
group = other-features {
        default service = deny
        login = PAM
        pap = PAM
        acl = acl-name
        service = service-name {
            allow-commands = "(show .*)|exit"
            deny-commands = ".*"
            local-user-name = "name"
        }
}

group = overriding-default-settings {
        default service = allow
        login = skey
        pap = des 0AmUKnIT2gheo
}

group = using-default-settings-only {
        default service = deny
        login = PAM
        pap = PAM
}
```
---
#### key (type: String)
Sets the encryption key to be used between the daemon and clients.

- *Default*: 'CHANGEME'

---
#### localusers (type: Hash)
Containing user definitions to appear in the user section of tac_plus.conf.
User definitions will get sorted by their names.

Supported attributes:
- member (type: String) to overrides $default_group
- password (type: String) will be set for login and pap
- cmd (type: Array containing Hashes)

- *Default*: {}

##### Example:
```yaml
tacacsplus::localusers:
  'using-default-settings-only':
  'overriding-default-settings':
    member: 'other_group'
  'other-features':
    password: 'secrect'
    cmd:
      telnet:
        -
          permit: '131\.108\.13\.[0-9]+'
          deny:   '*'
```

Will add these users in tac_plus.conf:
```
user = other-features {
  member = all_access
  login = des secrect
  pap = des secrect
  cmd = "telnet" {
    deny "*"
    permit "131\.108\.13\.[0-9]+"
  }
}

user = overriding-default-settings {
  member = other_group
}

user = using-default-settings-only {
  member = all_access
}
```
---
#### manage_init_script (type: Boolean)
Trigger to decide if the init script (/etc/init.d/tac_plus) should get managed.

- *Default*: false

---
#### manage_pam (type: Boolean)
Trigger to decide if the pam configuration file (/etc/pam.d/tac_plus) should get managed.

- *Default*: false

---
#### tacplus_pkg (type: String)
Name of the TACACS+ package to install / manage.

- *Default*: 'tacacs+'

---
#### tac_plus_template (type: String)
Name of the template file which will be used to manage /etc/tac_plus.conf.
For acceptable values please check the reference for the template function:
https://docs.puppet.com/puppet/latest/reference/function.html#template

Using the default of undef will use the included template.

- *Default*: undef

---
#### users (type: Hash)
Containing user definitions to appear in the user section of tac_plus.conf.
User definitions will get sorted by their names.

Supported attributes:
- member (type: String) to overrides $default_group
- password (type: String) will be set for login and pap
- cmd (type: Array containing Hashes)

- *Default*: {}

##### Example:
```yaml
tacacsplus::users:
  'using-default-settings-only':
  'overriding-default-settings':
    member: 'other_group'
  'other-features':
    password: 'secrect'
    cmd:
      telnet:
        -
          permit: '131\.108\.13\.[0-9]+'
          deny:   '*'
```

Will add these users in tac_plus.conf:
```
user = other-features {
  member = all_access
  login = des secrect
  pap = des secrect
  cmd = "telnet" {
    deny "*"
    permit "131\.108\.13\.[0-9]+"
  }
}

user = overriding-default-settings {
  member = other_group
}

user = using-default-settings-only {
  member = all_access
}
```
---
