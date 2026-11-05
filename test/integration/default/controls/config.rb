# frozen_string_literal: true

control 'containerd.config.file' do
  title 'The managed configuration contains the default containerd 2.4 settings and parses successfully'

  config_path = '/etc/containerd/config.toml'

  describe file(config_path) do
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    its('mode') { should cmp '0644' }
    its('content') { should start_with '# Managed by Salt, do not edit by hand' }
    its('content') { should match(/^version = 3$/) }
    its('content') { should include '"/etc/containerd/conf.d/*.toml"' }
    its('content') { should include 'config_path = "/etc/containerd/certs.d"' }
    its('content') { should include 'runtime_type = "io.containerd.runc.v2"' }
    its('content') { should include 'SystemdCgroup = true' }
  end

  describe command("/usr/local/bin/containerd --config #{config_path} config dump") do
    its('exit_status') { should eq 0 }
  end
end
