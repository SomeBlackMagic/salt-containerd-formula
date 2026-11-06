# -*- coding: utf-8 -*-
# vim: ft=sls

containerd-kernel-modules-file-clean:
  file.absent:
    - name: /etc/modules-load.d/containerd.conf

containerd-kernel-sysctl-file-clean:
  file.absent:
    - name: /etc/sysctl.d/90-containerd.conf
