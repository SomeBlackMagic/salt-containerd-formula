# frozen_string_literal: true

control 'containerd.config.file' do
  title 'Verify the configuration file'

  describe file('/etc/containerd/config.toml') do
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    its('mode') { should cmp '0644' }
    its('content') { should include 'version = 2' }
  end
end
