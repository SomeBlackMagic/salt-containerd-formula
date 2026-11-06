---
containerd:
  components:
    cni:
      enabled: true
    crictl:
      enabled: true
    nerdctl:
      enabled: true
      config:
        namespace: default
  kernel:
    enabled: true
  config:
    plugins:
      io.containerd.cri.v1.images:
        snapshotter: native
  registries:
    docker.io:
      server: https://registry-1.docker.io
  config_d:
    20-oom-score:
      oom_score: -500
