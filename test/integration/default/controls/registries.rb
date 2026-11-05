# frozen_string_literal: true

control 'containerd.config.registries' do
  title 'A registry creates hosts.toml and adjacent certificate files'

  registry_dir = '/etc/containerd/certs.d/docker.io'

  describe file(registry_dir) do
    it { should be_directory }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    its('mode') { should cmp '0755' }
  end

  describe file("#{registry_dir}/hosts.toml") do
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    its('mode') { should cmp '0644' }
    its('content') { should start_with '# Managed by Salt, do not edit by hand' }
    its('content') { should include 'server = "https://registry-1.docker.io"' }
    its('content') { should include '[host."https://mirror.example.com"]' }
    its('content') { should include 'capabilities = ["pull", "resolve"]' }
    its('content') { should include 'ca = "ca.crt"' }
  end

  describe file("#{registry_dir}/ca.crt") do
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    its('mode') { should cmp '0644' }
    its('content') { should include 'test-ca-only' }
  end
end

control 'containerd.config.registries_preserve' do
  title 'Unmanaged host directories remain when registries_purge is false'

  describe file('/etc/containerd/certs.d/unmanaged.example') do
    it { should be_directory }
  end
end
