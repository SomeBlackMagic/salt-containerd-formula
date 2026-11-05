# frozen_string_literal: true

control 'containerd.config.registries_purge' do
  title 'Purge removes unmanaged host directories and keeps managed hosts'

  describe file('/etc/containerd/certs.d/unmanaged.example') do
    it { should_not exist }
  end

  describe file('/etc/containerd/certs.d/docker.io/hosts.toml') do
    it { should be_file }
    its('content') { should include 'server = "https://registry-1.docker.io"' }
  end
end
