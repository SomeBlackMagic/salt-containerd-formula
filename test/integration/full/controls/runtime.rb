# frozen_string_literal: true

control 'containerd.full.runtime' do
  title 'Containerd pulls and runs a BusyBox container with the native snapshotter'

  image = 'docker.io/library/busybox:1.36.1'
  pull = "sudo ctr images pull --local --platform linux/amd64 --snapshotter native #{image}"
  run = "sudo ctr run --rm --snapshotter native --net-host #{image} full-smoke /bin/true"

  describe command("#{pull} && #{run}") do
    its('exit_status') { should eq 0 }
  end
end
