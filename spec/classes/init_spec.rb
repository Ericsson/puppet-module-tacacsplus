require 'spec_helper'
describe 'tacacsplus' do
  mandatory_params = {}
  let(:facts) { mandatory_global_facts }
  let(:params) { mandatory_params }

  tac_plus_conf_header = <<-END.gsub(/^\s+\|/, '')
    |#
    |## This file is maintained by puppet. Manual changes will be overwritten.
    |## Add entries using Puppet.
    |#
    |
    |## Define Users to be authed by PAM
  END
  tac_plus_conf_key = <<-END.gsub(/^\s+\|/, '')
    |key = "CHANGEME"
    |
  END
  tac_plus_conf_footer = <<-END.gsub(/^\s+\|/, '')
    |group = show_only {
    |        default service = deny
    |        login = PAM
    |        pap = PAM
    |        service = junos-exec {
    |                local-user-name = remote
    |                allow-commands = "(show .*)|exit"
    |                allow-configuration = ""
    |                deny-commands = ".*"
    |                deny-configuration = ""
    |        }
    |}
    |
    |# Admin users
    |group = all_access {
    |    default service = permit
    |    login = PAM
    |    pap   = PAM
    |
    |    # JunOS related settings
    |    service = junos-exec {
    |        local-user-name = remote
    |        allow-commands = ".*"
    |        allow-configuration = ".*"
    |        deny-commands = ""
    |        deny-configuration = ""
    |    }
    |    service = exec {
    |    priv-lvl = 15
    |    cisco-av-pair="shell:roles=network-admin"
    |    }
    |}
  END

  describe 'with defaults for all parameters on supported osfamily' do
    it { should compile.with_all_deps }
    it { should contain_class('tacacsplus') }
    it { should contain_package('tacacs+').with({ 'ensure' => 'installed' }) }
    it { should_not contain_file('/etc/init.d/tac_plus') }
    it do
      should contain_file('/etc/tac_plus.conf').with({
        'ensure'  => 'file',
        'content' => tac_plus_conf_header + tac_plus_conf_key + tac_plus_conf_footer,
        'owner'   => 'root',
        'group'   => 'root',
        'require' => 'Package[tacacs+]',
        'notify'  => 'Service[tac_plus]',
      })
    end
    it { should_not contain_file('/etc/pam.d/tac_plus') }
    it do
      should contain_service('tac_plus').with({
        'ensure'    => 'running',
        'enable'    => 'true',
        'hasstatus' => 'false',
        'pattern'   => 'tac_plus',
      })
    end
  end

  context 'with defaults for all parameters on unsupported osfamily' do
    let(:facts) { { :osfamily => 'Debian' } }
    it 'should fail' do
      expect { should contain_class(subject) }.to raise_error(Puppet::Error, /Operating system not supported/)
    end
  end

  context 'with tacplus_pkg set to valid string <package_name>' do
    let(:params) { mandatory_params.merge({ :tacplus_pkg => 'package_name', :manage_pam => true }) }
    it { should contain_package('package_name') }
    it { should contain_file('/etc/tac_plus.conf').with_require('Package[package_name]') }
    it { should contain_file('/etc/pam.d/tac_plus').with_require('Package[package_name]') }
  end

  context 'with acl set to valid hash' do
    let(:params) do
      {
        :acl => {
          'acl_all_features' => [{ 'permit' => '127.0.0.1' }, { 'permit' => '192.168.2.*' }, { 'deny' => '192.168.0.*' }, { 'deny' => '192.168.1.*' }],
          'acl_deny_only'    => [{ 'deny' => '192.168.0.*' }],
          'acl_permit_only'  => [{ 'permit' => '*' }],
        }
      }
    end
    acl_content = <<-END.gsub(/^\s+\|/, '')
      |acl = "acl_all_features" {
      |    permit = 127.0.0.1
      |    permit = 192.168.2.*
      |    deny = 192.168.0.*
      |    deny = 192.168.1.*
      |}
      |
      |acl = "acl_deny_only" {
      |    deny = 192.168.0.*
      |}
      |
      |acl = "acl_permit_only" {
      |    permit = *
      |}
      |
    END

    it { should contain_file('/etc/tac_plus.conf').with_content(tac_plus_conf_header + acl_content + tac_plus_conf_key + tac_plus_conf_footer) }
  end

  context 'with users set to valid hash' do
    let(:params) { mandatory_params.merge({ :users => { 'user1' => {}, 'user2' => {} } }) }
    users_content = <<-END.gsub(/^\s+\|/, '')
      |user = user1 {
      |  member = all_access
      |}
      |
      |user = user2 {
      |  member = all_access
      |}
      |
    END
    it { should contain_file('/etc/tac_plus.conf').with_content(tac_plus_conf_header + users_content + tac_plus_conf_key + tac_plus_conf_footer) }
  end

  context 'with users set to valid hash providing <member> key' do
    let(:params) { mandatory_params.merge({ :users => { 'user1' => { 'member' => 'specific_access' } } }) }
    users_content = <<-END.gsub(/^\s+\|/, '')
      |user = user1 {
      |  member = specific_access
      |}
      |
    END
    it { should contain_file('/etc/tac_plus.conf').with_content(tac_plus_conf_header + users_content + tac_plus_conf_key + tac_plus_conf_footer) }
  end

  context 'with users set to valid hash providing <password> key' do
    let(:params) { mandatory_params.merge({ :users => { 'user1' => { 'password' => 'secret' } } }) }
    users_content = <<-END.gsub(/^\s+\|/, '')
      |user = user1 {
      |  member = all_access
      |  login = des secret
      |  pap = des secret
      |}
      |
    END
    it { should contain_file('/etc/tac_plus.conf').with_content(tac_plus_conf_header + users_content + tac_plus_conf_key + tac_plus_conf_footer) }
  end

  context 'with users set to valid hash providing <cmd> key' do
    let(:params) { mandatory_params.merge({ :users => { 'user1' => { 'cmd' => { 'command' => [{ 'permit' => 'all' }, { 'deny' => 'nothing' }] } } } }) }
    users_content = <<-END.gsub(/^\s+\|/, '')
      |user = user1 {
      |  member = all_access
      |  cmd = "command" {
      |    permit "all"
      |    deny "nothing"
      |  }
      |}
      |
    END
    it { should contain_file('/etc/tac_plus.conf').with_content(tac_plus_conf_header + users_content + tac_plus_conf_key + tac_plus_conf_footer) }
  end

  context 'with users set to valid hash providing multiple <cmd> keys' do
    let(:params) { mandatory_params.merge({ :users => { 'user1' => { 'cmd' => { 'command1' => [{ 'permit' => 'all' }], 'command2' => [{ 'deny' => 'all' }] } } } }) }
    users_content = <<-END.gsub(/^\s+\|/, '')
      |user = user1 {
      |  member = all_access
      |  cmd = "command1" {
      |    permit "all"
      |  }
      |  cmd = "command2" {
      |    deny "all"
      |  }
      |}
      |
    END
    it { should contain_file('/etc/tac_plus.conf').with_content(tac_plus_conf_header + users_content + tac_plus_conf_key + tac_plus_conf_footer) }
  end

  context 'with groups set to valid hash' do
    let(:params) { mandatory_params.merge({ :groups => { 'group1' => {}, 'group2' => {} } }) }
    groups_content = <<-END.gsub(/^\s+\|/, '')
      |group = group1 {
      |        default service = deny
      |        login = PAM
      |        pap = PAM
      |}
      |
      |group = group2 {
      |        default service = deny
      |        login = PAM
      |        pap = PAM
      |}
      |
    END
    it { should contain_file('/etc/tac_plus.conf').with_content(tac_plus_conf_header + tac_plus_conf_key + groups_content + tac_plus_conf_footer) }
  end

  context 'with groups set to valid hash providing <default_service> key' do
    let(:params) { mandatory_params.merge({ :groups => { 'group1' => { 'default_service' => 'allow' } } }) }
    groups_content = <<-END.gsub(/^\s+\|/, '')
      |group = group1 {
      |        default service = allow
      |        login = PAM
      |        pap = PAM
      |}
      |
    END
    it { should contain_file('/etc/tac_plus.conf').with_content(tac_plus_conf_header + tac_plus_conf_key + groups_content + tac_plus_conf_footer) }
  end

  context 'with groups set to valid hash providing <login> key' do
    let(:params) { mandatory_params.merge({ :groups => { 'group1' => { 'login' => 'specific' } } }) }
    groups_content = <<-END.gsub(/^\s+\|/, '')
      |group = group1 {
      |        default service = deny
      |        login = specific
      |        pap = PAM
      |}
      |
    END
    it { should contain_file('/etc/tac_plus.conf').with_content(tac_plus_conf_header + tac_plus_conf_key + groups_content + tac_plus_conf_footer) }
  end

  context 'with groups set to valid hash providing <pap> key' do
    let(:params) { mandatory_params.merge({ :groups => { 'group1' => { 'pap' => 'specific' } } }) }
    groups_content = <<-END.gsub(/^\s+\|/, '')
      |group = group1 {
      |        default service = deny
      |        login = PAM
      |        pap = specific
      |}
      |
    END
    it { should contain_file('/etc/tac_plus.conf').with_content(tac_plus_conf_header + tac_plus_conf_key + groups_content + tac_plus_conf_footer) }
  end

  context 'with groups set to valid hash providing <acl> key' do
    let(:params) { mandatory_params.merge({ :groups => { 'group1' => { 'acl' => 'acl1' } } }) }
    groups_content = <<-END.gsub(/^\s+\|/, '')
      |group = group1 {
      |        default service = deny
      |        login = PAM
      |        pap = PAM
      |        acl = acl1
      |}
      |
    END
    it { should contain_file('/etc/tac_plus.conf').with_content(tac_plus_conf_header + tac_plus_conf_key + groups_content + tac_plus_conf_footer) }
  end

  context 'with groups set to valid hash providing <service> key' do
    let(:params) { mandatory_params.merge({ :groups => { 'group1' => { 'service' => { 'exec' => [{ 'priv-lvl' => '15' }, { 'other' => '242' }] } } } }) }

    groups_content = <<-END.gsub(/^\s+\|/, '')
      |group = group1 {
      |        default service = deny
      |        login = PAM
      |        pap = PAM
      |        service = exec {
      |            priv-lvl = "15"
      |            other = "242"
      |        }
      |}
      |
    END
    it { should contain_file('/etc/tac_plus.conf').with_content(tac_plus_conf_header + tac_plus_conf_key + groups_content + tac_plus_conf_footer) }
  end

  context 'with groups set to valid hash providing multiple <service> keys' do
    let(:params) { mandatory_params.merge({ :groups => { 'group1' => { 'service' => { 'exec' => [{ 'priv-lvl' => '15' }], 'other' => [{ 'other' => '242' }] } } } }) }
    groups_content = <<-END.gsub(/^\s+\|/, '')
      |group = group1 {
      |        default service = deny
      |        login = PAM
      |        pap = PAM
      |        service = exec {
      |            priv-lvl = "15"
      |        }
      |        service = other {
      |            other = "242"
      |        }
      |}
      |
    END
    it { should contain_file('/etc/tac_plus.conf').with_content(tac_plus_conf_header + tac_plus_conf_key + groups_content + tac_plus_conf_footer) }
  end
  context 'with localusers set to valid hash' do
    let(:params) { mandatory_params.merge({ :localusers => { 'user1' => {}, 'user2' => {} } }) }
    localusers_content = <<-END.gsub(/^\s+\|/, '')
      |user = user1 {
      |  member = all_access
      |}
      |
      |user = user2 {
      |  member = all_access
      |}
      |
    END
    it { should contain_file('/etc/tac_plus.conf').with_content(tac_plus_conf_header + localusers_content + tac_plus_conf_key + tac_plus_conf_footer) }
  end

  context 'with localusers set to valid hash providing <member> key' do
    let(:params) { mandatory_params.merge({ :localusers => { 'user1' => { 'member' => 'specific_access' } } }) }
    localusers_content = <<-END.gsub(/^\s+\|/, '')
      |user = user1 {
      |  member = specific_access
      |}
      |
    END
    it { should contain_file('/etc/tac_plus.conf').with_content(tac_plus_conf_header + localusers_content + tac_plus_conf_key + tac_plus_conf_footer) }
  end

  context 'with localusers set to valid hash providing <password> key' do
    let(:params) { mandatory_params.merge({ :localusers => { 'user1' => { 'password' => 'secret' } } }) }
    localusers_content = <<-END.gsub(/^\s+\|/, '')
      |user = user1 {
      |  member = all_access
      |  login = des secret
      |  pap = des secret
      |}
      |
    END
    it { should contain_file('/etc/tac_plus.conf').with_content(tac_plus_conf_header + localusers_content + tac_plus_conf_key + tac_plus_conf_footer) }
  end

  context 'with localusers set to valid hash providing <cmd> key' do
    let(:params) { mandatory_params.merge({ :localusers => { 'user1' => { 'cmd' => { 'command' => [{ 'permit' => 'all' }, { 'deny' => 'nothing' }] } } } }) }
    localusers_content = <<-END.gsub(/^\s+\|/, '')
      |user = user1 {
      |  member = all_access
      |  cmd = "command" {
      |    permit "all"
      |    deny "nothing"
      |  }
      |}
      |
    END
    it { should contain_file('/etc/tac_plus.conf').with_content(tac_plus_conf_header + localusers_content + tac_plus_conf_key + tac_plus_conf_footer) }
  end

  context 'with default_group set to valid string' do
    let(:params) { mandatory_params.merge({ :default_group => 'other_access', :localusers => { 'localuser1' => {} }, :users => { 'user1' => {} } }) }
    default_group_content = <<-END.gsub(/^\s+\|/, '')
      |user = user1 {
      |  member = other_access
      |}
      |
      |user = localuser1 {
      |  member = other_access
      |}
      |
    END
    it { should contain_file('/etc/tac_plus.conf').with_content(tac_plus_conf_header + default_group_content + tac_plus_conf_key + tac_plus_conf_footer) }
  end

  context 'with default_group_login set to valid string' do
    let(:params) { mandatory_params.merge({ :default_group_login => 'other', :groups => { 'group1' => {} } }) }
    default_group_login_content = <<-END.gsub(/^\s+\|/, '')
      |group = group1 {
      |        default service = deny
      |        login = other
      |        pap = PAM
      |}
      |
    END
    it { should contain_file('/etc/tac_plus.conf').with_content(tac_plus_conf_header + tac_plus_conf_key + default_group_login_content + tac_plus_conf_footer) }
  end

  context 'with default_group_pap set to valid string' do
    let(:params) { mandatory_params.merge({ :default_group_pap => 'other', :groups => { 'group1' => {} } }) }
    default_group_login_content = <<-END.gsub(/^\s+\|/, '')
      |group = group1 {
      |        default service = deny
      |        login = PAM
      |        pap = other
      |}
      |
    END
    it { should contain_file('/etc/tac_plus.conf').with_content(tac_plus_conf_header + tac_plus_conf_key + default_group_login_content + tac_plus_conf_footer) }
  end

  context 'with default_group_default_service set to valid string' do
    let(:params) { mandatory_params.merge({ :default_group_default_service => 'other', :groups => { 'group1' => {} } }) }
    default_group_login_content = <<-END.gsub(/^\s+\|/, '')
      |group = group1 {
      |        default service = other
      |        login = PAM
      |        pap = PAM
      |}
      |
    END
    it { should contain_file('/etc/tac_plus.conf').with_content(tac_plus_conf_header + tac_plus_conf_key + default_group_login_content + tac_plus_conf_footer) }
  end

  context 'with tac_plus_template set to valid string' do
    let(:params) { mandatory_params.merge({ :tac_plus_template => 'other/template.erb' }) }
    # don't know any way to test parameterized templates, any hints would be very welcome <phil.friderici@i-tee.de>
  end

  context 'with manage_init_script set to valid boolean <true>' do
    let(:params) { { :manage_init_script => true } }
    manage_init_script_content = File.read(fixtures('tac_plus-redhat-init'))
    it do
      should contain_file('/etc/init.d/tac_plus').with({
        'ensure'  => 'file',
        'content' => manage_init_script_content,
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0744',
        'before'  => 'Service[tac_plus]',
      })
    end
  end

  context 'with manage_pam set to valid boolean <true>' do
    let(:params) { mandatory_params.merge({ :manage_pam => true }) }
    manage_pam_content = <<-END.gsub(/^\s+\|/, '')
      |#
      |## This file is maintained by puppet. Manual changes will be overwritten.
      |## Template is available at tacacsplus/templates/tac_plus.erb
      |## Add entries using Puppet.
      |#
      |
      |#%PAM-1.0
      |auth [ignore=ignore success=done default=die] /opt/quest/lib64/security/pam_vas3.so
      |account [ignore=ignore success=done default=die] /opt/quest/lib64/security/pam_vas3.so
      |password [ignore=ignore success=done default=die] /opt/quest/lib64/security/pam_vas3.so
      |session [ignore=ignore success=done default=die] /opt/quest/lib64/security/pam_vas3.so
      |
    END
    it do
      should contain_file('/etc/pam.d/tac_plus').with({
        'ensure'  => 'file',
        'content' => manage_pam_content,
        'owner'   => 'root',
        'group'   => 'root',
        'require' => 'Package[tacacs+]',
        'before'  => 'Service[tac_plus]',
      })
    end
  end

  describe 'variable type and content validations' do
    validations = {
      'string' => {
        :name    => %w(tac_plus_template),
        :valid   => [], # don't know any way to test parameterized templates, any hints would be very welcome <phil.friderici@i-tee.de>
        :invalid => [%w(array), { 'ha' => 'sh' }, true, false], # remove integer & float as implementation does not catch them
        :message => 'is not a string',
      },
    }

    validations.sort.each do |type, var|
      var[:name].each do |var_name|
        var[:params] = {} if var[:params].nil?
        var[:valid].each do |valid|
          context "when #{var_name} (#{type}) is set to valid #{valid} (as #{valid.class})" do
            let(:params) { [mandatory_params, var[:params], { :"#{var_name}" => valid, }].reduce(:merge) }
            it { should compile }
          end
        end

        var[:invalid].each do |invalid|
          context "when #{var_name} (#{type}) is set to invalid #{invalid} (as #{invalid.class})" do
            let(:params) { [mandatory_params, var[:params], { :"#{var_name}" => invalid, }].reduce(:merge) }
            it 'should fail' do
              expect { should contain_class(subject) }.to raise_error(Puppet::Error, /#{var[:message]}/)
            end
          end
        end
      end # var[:name].each
    end # validations.sort.each
  end # describe 'variable type and content validations'
end
