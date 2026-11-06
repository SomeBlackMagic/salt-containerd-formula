# frozen_string_literal: true

control 'containerd.crictl.install' do
  title 'The pinned crictl binary is installed and executable'

  version = '1.37.0'
  target = "/opt/containerd/crictl/#{version}/crictl"

  describe file('/usr/local/bin/crictl') do
    it { should be_symlink }
    its('link_path') { should eq target }
  end

  describe file(target) do
    it { should be_file }
    it { should be_executable }
  end
end

control 'containerd.crictl.config' do
  title 'The configured CRI endpoints are serialized to YAML'

  endpoint = 'unix:///run/containerd/containerd.sock'

  describe file('/etc/crictl.yaml') do
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    its('mode') { should cmp '0644' }
    its('content') { should match(/runtime-endpoint: #{Regexp.escape(endpoint)}/) }
    its('content') { should match(/image-endpoint: #{Regexp.escape(endpoint)}/) }
  end
end

control 'containerd.crictl.info' do
  title 'crictl can query the running containerd CRI service'

  describe command('/usr/local/bin/crictl info') do
    its('exit_status') { should eq 0 }
  end
end
