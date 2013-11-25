require 'spec_helper'
describe 'tacacsplus' do

  context 'with default options' do
    let(:facts) { { :osfamily => 'RedHat' } }

    it { should include_class('tacacsplus') }
  end
end
