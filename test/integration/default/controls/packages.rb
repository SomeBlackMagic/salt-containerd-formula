# frozen_string_literal: true

control 'containerd.package.install' do
  title 'The required package should be installed'

  describe package('containerd') do
    it { should be_installed }
  end
end
