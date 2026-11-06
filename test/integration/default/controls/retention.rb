# frozen_string_literal: true

control 'containerd.package.retention' do
  title 'Keep the current version and two most recently modified older versions'

  prefix = '/opt/containerd/containerd'

  %w[2.4.2 2.9 2.10].each do |version|
    describe file("#{prefix}/#{version}") do
      it { should be_directory }
    end
  end

  describe file("#{prefix}/2.8") do
    it { should_not exist }
  end

  describe file('/usr/local/bin/containerd') do
    it { should be_symlink }
    its('link_path') { should eq "#{prefix}/2.4.2/bin/containerd" }
  end
end
