# frozen_string_literal: true

control 'containerd.package.install' do
  title 'The pinned containerd binaries should be installed'

  version = '2.4.2'
  prefix = '/opt/containerd/containerd'
  bin_dir = '/usr/local/bin'
  binaries = %w[containerd containerd-shim-runc-v2 ctr]

  describe file("#{prefix}/#{version}") do
    it { should be_directory }
    it { should be_owned_by 'root' }
    its('group') { should eq 'root' }
  end

  describe file("#{prefix}/#{version}/bin") do
    it { should be_directory }
  end

  binaries.each do |name|
    describe file("#{prefix}/#{version}/bin/#{name}") do
      it { should be_file }
      it { should be_executable }
    end

    describe file("#{bin_dir}/#{name}") do
      it { should be_symlink }
      its('link_path') { should eq "#{prefix}/#{version}/bin/#{name}" }
    end
  end

  describe command("#{bin_dir}/containerd --version") do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/2\.4\.2/) }
  end
end
