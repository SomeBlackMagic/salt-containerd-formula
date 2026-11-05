# frozen_string_literal: true

control 'containerd.service.unit' do
  title 'The containerd systemd unit and drop-in are installed'

  unit = '/etc/systemd/system/containerd.service'
  drop_in = '/etc/systemd/system/containerd.service.d/override.conf'

  [unit, drop_in].each do |path|
    describe file(path) do
      it { should be_file }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
      its('mode') { should cmp '0644' }
    end
  end

  describe file(unit) do
    its('content') { should include 'ExecStart=/usr/local/bin/containerd' }
  end

  describe command("systemd-analyze verify #{unit}") do
    its('exit_status') { should eq 0 }
  end
end

control 'containerd.service.running' do
  title 'The containerd service is enabled and running'

  describe service('containerd') do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end

  describe file('/run/containerd/containerd.sock') do
    it { should be_socket }
  end

  describe command('ctr version') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/Server:/) }
  end
end
