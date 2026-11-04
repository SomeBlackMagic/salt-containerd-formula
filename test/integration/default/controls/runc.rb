# frozen_string_literal: true

control 'containerd.runc.install' do
  title 'The pinned runc binary is installed with executable permissions'

  version = '1.5.2'
  binary = "/opt/containerd/runc/#{version}/runc"

  describe file(binary) do
    it { should be_file }
    it { should be_owned_by 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0755' }
  end
end

control 'containerd.runc.symlink' do
  title 'The runc link targets the pinned binary'

  version = '1.5.2'
  link = '/usr/local/sbin/runc'

  describe file(link) do
    it { should be_symlink }
    its('link_path') { should eq "/opt/containerd/runc/#{version}/runc" }
  end
end

control 'containerd.runc.version' do
  title 'The linked runc binary reports the pinned version'

  version = '1.5.2'
  link = '/usr/local/sbin/runc'

  describe command("#{link} --version") do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/runc version #{Regexp.escape(version)}(?:\s|$)/) }
  end
end
