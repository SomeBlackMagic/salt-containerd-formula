# frozen_string_literal: true

control 'containerd.full.components' do
  title 'CNI, crictl, and nerdctl are installed and configured'

  %w[/opt/cni/bin/bridge /usr/local/bin/crictl /usr/local/bin/nerdctl].each do |path|
    describe file(path) do
      it { should be_executable }
    end
  end

  %w[/etc/crictl.yaml /etc/nerdctl/nerdctl.toml].each do |path|
    describe file(path) do
      it { should be_file }
    end
  end

  describe command('/usr/local/bin/crictl info') do
    its('exit_status') { should eq 0 }
  end
end

control 'containerd.full.kernel' do
  title 'Kernel module and sysctl configuration is persisted'

  %w[/etc/modules-load.d/containerd.conf /etc/sysctl.d/90-containerd.conf].each do |path|
    describe file(path) do
      it { should be_file }
      it { should be_owned_by 'root' }
    end
  end
end

control 'containerd.full.config' do
  title 'Registry, drop-in, and native snapshotter configuration is present'

  %w[/etc/containerd/certs.d/docker.io/hosts.toml /etc/containerd/conf.d/20-oom-score.toml].each do |path|
    describe file(path) do
      it { should be_file }
      it { should be_owned_by 'root' }
    end
  end

  describe file('/etc/containerd/config.toml') do
    its('content') { should include 'snapshotter = "native"' }
  end
end
