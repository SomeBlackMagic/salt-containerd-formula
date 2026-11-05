# frozen_string_literal: true

control 'containerd.service.enabled' do
  title 'The service is installed and enabled without starting it'

  describe service('containerd') do
    it { should be_installed }
    it { should be_enabled }
    it { should_not be_running }
  end
end
