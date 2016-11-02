# puppet-module-tacacsplus

Changelog

## 2016-10-30 - Release 1.0.0
### Breaking News

This release breaks with backward compatibility.

##### parameters that have been renamed:
- `$tac_key` is now called `$key`.

##### parameters that got new default values:
- `$acl`, `$users`, `$localusers`, and `$groups` now defaults to an empty hash `{}` instead of the string `NONE`.

##### default functionality that have been changed:
- managing the init script is now optional since some packages come with a working init script. (`$manage_init_script`)
- managing the pam config is optional now as it is not universally needed. (`$manage_pam`)

#### Features
- Add support to specify other templates for /etc/tac_plus.conf (`$tac_plus_template`)
- Add support for Puppet 3 up to 3.8.0
- Add support for Puppet 4 up to 4.7.0
- Add support for Ruby 2.0.0, 2.1.0, and 2.3.1

#### Bugfixes
- Add README
- Cleanup linebreaks and sections in tac_plus.conf template.
- Enhance the spec tests to feature much more test cases.

#### Upgrading from 0.1.0
As the template for /etc/tac_plus.conf was changed, it is expected that the service will restart on the first run.

###### minimum
- Rename the parameter `$tac_key` to `$key` in your configuration.

###### enhance backward compatibility
- Rename the parameter `$tac_key` to `$key` in your configuration.
- To keep managing the init script and PAM configuration, add these parameters:
```yaml
tacacsplus::manage_init_script: true
tacacsplus::manage_pam:         true
```
- In the unlikely case that one of `$acl`, `$users`, `$localusers`, or `$groups` was explicitly set to `NONE`, you need to change these occurrences to an empty hash `{}`.
