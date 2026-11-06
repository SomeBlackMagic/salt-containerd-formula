# frozen_string_literal: true

control 'containerd.clean.resources' do
  title 'Formula files and binaries are removed after cleanup'

  paths = %w[
    /etc/containerd/config.toml
    /etc/containerd/conf.d
    /etc/systemd/system/containerd.service
    /etc/systemd/system/containerd.service.d/override.conf
    /etc/modules-load.d/containerd.conf
    /etc/sysctl.d/90-containerd.conf
    /usr/local/bin/containerd
    /usr/local/bin/containerd-shim-runc-v2
    /usr/local/bin/ctr
    /usr/local/sbin/runc
    /opt/containerd/containerd
    /opt/containerd/runc
  ]

  paths.each do |path|
    describe file(path) do
      it { should_not exist }
    end
  end

  describe service('containerd') do
    it { should_not be_running }
    it { should_not be_enabled }
  end
end

control 'containerd.clean.data' do
  title 'Container data remains when purge_data is false'

  describe file('/var/lib/containerd/clean-fixture') do
    it { should be_file }
    its('content') { should include 'keep' }
  end
end
