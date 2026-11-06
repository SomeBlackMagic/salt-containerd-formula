# frozen_string_literal: true

control 'containerd.config.dropins' do
  title 'A config_d entry creates a managed TOML drop-in and is merged by containerd'

  dropin_path = '/etc/containerd/conf.d/20-oom-score.toml'

  describe file(dropin_path) do
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    its('mode') { should cmp '0644' }
    its('content') { should start_with '# Managed by Salt, do not edit by hand' }
    its('content') { should include 'oom_score = -500' }
  end

  describe file('/etc/containerd/conf.d/20-sandbox.toml') do
    it { should_not exist }
  end

  config_path = '/etc/containerd/config.toml'
  dump_command = "/usr/local/bin/containerd --config #{config_path} config dump"
  describe command(dump_command) do
    its('exit_status') { should eq 0 }
    its('stdout') { should include 'oom_score = -500' }
  end
end
