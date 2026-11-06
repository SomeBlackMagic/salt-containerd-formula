# frozen_string_literal: true

control 'containerd.cni.install' do
  title 'The pinned CNI plugins are executable in the configured directory'

  version = '1.9.1'
  directory = '/opt/cni/bin'
  plugins = %w[bridge loopback host-local]

  plugins.each do |plugin|
    describe file("#{directory}/#{plugin}") do
      it { should be_symlink }
      its('link_path') { should eq "/opt/containerd/cni/#{version}/#{plugin}" }
    end

    describe file("/opt/containerd/cni/#{version}/#{plugin}") do
      it { should be_file }
      it { should be_executable }
    end
  end

  describe file('/etc/cni/net.d') do
    it { should_not exist }
  end
end
