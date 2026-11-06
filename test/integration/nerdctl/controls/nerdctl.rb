# frozen_string_literal: true

control 'containerd.nerdctl.install' do
  title 'The pinned nerdctl binary is installed and executable'

  version = '2.4.2'
  target = "/opt/containerd/nerdctl/#{version}/nerdctl"

  describe file('/usr/local/bin/nerdctl') do
    it { should be_symlink }
    its('link_path') { should eq target }
  end

  describe file(target) do
    it { should be_file }
    it { should be_executable }
  end
end

control 'containerd.nerdctl.config' do
  title 'The configured nerdctl namespace is serialized to TOML'

  describe file('/etc/nerdctl/nerdctl.toml') do
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    its('mode') { should cmp '0644' }
    its('content') { should match(/^namespace = "default"$/) }
  end
end

control 'containerd.nerdctl.version' do
  title 'nerdctl version reports the running containerd server'

  describe command('/usr/local/bin/nerdctl version') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/Server:/) }
  end
end
