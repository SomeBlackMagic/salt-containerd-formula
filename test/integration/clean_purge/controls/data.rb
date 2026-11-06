# frozen_string_literal: true

control 'containerd.clean.purge_data' do
  title 'Container data is removed when purge_data is true'

  describe file('/var/lib/containerd') do
    it { should_not exist }
  end
end
