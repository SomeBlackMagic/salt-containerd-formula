# frozen_string_literal: true

control 'containerd.kernel.modules' do
  title 'The requested modules are persisted for boot'

  describe file('/etc/modules-load.d/containerd.conf') do
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    its('mode') { should cmp '0644' }
    its('content') { should eq "overlay\nbr_netfilter\n" }
  end
end

control 'containerd.kernel.sysctl' do
  title 'The requested sysctls are persisted for boot'

  describe file('/etc/sysctl.d/90-containerd.conf') do
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    its('mode') { should cmp '0644' }
    its('content') { should include "net.ipv4.ip_forward = 1\n" }
    its('content') { should include "net.bridge.bridge-nf-call-iptables = 1\n" }
    its('content') { should include "net.bridge.bridge-nf-call-ip6tables = 1\n" }
  end
end
