require 'spec_helper'
describe 'tacacsplus' do

  context 'with default params on osfamily RedHat' do
    let :facts do
      {
        :osfamily => 'RedHat'
      }
    end
    it { should contain_class('tacacsplus') }
    it { should contain_package('tacacs+').with ({
        'ensure' => 'installed'
      })
    }

    it { should_not contain_file('/etc/init.d/tac_plus') }

    it { should contain_file('/etc/tac_plus.conf').with({
      'ensure'  => 'file',
      'owner'   => 'root',
      'group'   => 'root',
      'require' => 'Package[tacacs+]',
      'notify'  => 'Service[tac_plus]',
      })
    }

    it { should contain_file('/etc/tac_plus.conf').with_content(/^key = \"CHANGEME\"$/) }
    it { should_not contain_file('/etc/tac_plus.conf').with_content(/user = /) }
    it { should_not contain_file('/etc/tac_plus.conf').with_content(/^acl = /) }

    it { should_not contain_file('/etc/pam.d/tac_plus') }

    it { should contain_service('tac_plus').with({
      'ensure'    => 'running',
      'enable'    => 'true',
      'hasstatus' => 'false',
      'pattern'   => 'tac_plus',
      })
    }
  end

  context 'with non-supported osfamily Debian' do
    let :facts do
      {
        :osfamily => 'Debian'
      }
    end
    it 'should fail' do
      expect {
        should contain_class('tacacsplus')
      }.to raise_error(Puppet::Error,/Operating system not supported/)
    end
  end

  context 'with users param set on valid osfamily' do
    let :facts do
      {
        :osfamily => 'RedHat'
      }
    end

    let :params do
      {
        :users => {
          'username' => {
            'member' => 'all_access',
            'password' => 'secret',
            'cmd' => {
              'command' => [{'permit' => 'all'},{'deny' => 'nothing'}]
            }
          }
        }
      }
    end

    it { should contain_file('/etc/tac_plus.conf').with_content(/^user = username {$/) }
    it { should contain_file('/etc/tac_plus.conf').with_content(/^  member = all_access$/) }
    it { should contain_file('/etc/tac_plus.conf').with_content(/^  login = des secret$/) }
    it { should contain_file('/etc/tac_plus.conf').with_content(/^  cmd = \"command\" {$/) }
    it { should contain_file('/etc/tac_plus.conf').with_content(/^    permit \"all\"$/) }
    it { should contain_file('/etc/tac_plus.conf').with_content(/^    deny \"nothing\"$/) }
  end

  context 'with acl param set on valid osfamily' do
    let :facts do
      {
        :osfamily => 'RedHat'
      }
    end

    let :params do
      {
        :acl => {
          'acl_name' => [{'permit' => '127.0.0.1'},{'deny' => '192.168.0.*'}],
          'other_acl' => [{'permit' => '*'}]
        }
      }
    end

    it { should contain_file('/etc/tac_plus.conf').with_content(/^acl = \"acl_name\" {\n    permit = 127.0.0.1\n    deny = 192.168.0.*\n}$/) }
    it { should contain_file('/etc/tac_plus.conf').with_content(/^acl = \"other_acl\" {\n    permit = \*\n}$/) }
  end

  context 'with groups param set on valid osfamily' do
    let :facts do
      {
        :osfamily => 'RedHat'
      }
    end

    let :params do
      {
        :groups => {
          'group_name' => {
            'acl' => 'acl_name',
            'service' => {
              'exec' => [{'priv-lvl' => '15'}]
            }
          }
        }
      }
    end

    it { should contain_file('/etc/tac_plus.conf').with_content(/^group = group_name {\n        default service = deny\n        login = PAM\n        pap = PAM\n        acl = acl_name\n        service = exec {\n            priv-lvl = \"15\"\n        }\n}$/) }
  end
end
