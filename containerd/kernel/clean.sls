# -*- coding: utf-8 -*-
# vim: ft=sls

include:
  - containerd.service.clean

containerd-kernel-clean-modules-file-absent:
  file.absent:
    - name: /etc/modules-load.d/containerd.conf
    - require:
      - sls: containerd.service.clean

containerd-kernel-clean-sysctl-file-absent:
  file.absent:
    - name: /etc/sysctl.d/90-containerd.conf
    - require:
      - sls: containerd.service.clean
