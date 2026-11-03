# -*- coding: utf-8 -*-
# vim: ft=yaml
---
containerd:
  pkg:
    name: containerd
  service:
    name: containerd
  config: /etc/containerd/config.toml

  tofs:
    files_switch:
      - any/path/can/be/used/here
      - id
      - roles
      - osfinger
      - os
      - os_family
