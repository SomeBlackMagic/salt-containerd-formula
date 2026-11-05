# -*- coding: utf-8 -*-
# vim: ft=yaml
---
containerd:
  config_d:
    20-oom-score:
      oom_score: -500
  tofs:
    files_switch:
      - any/path/can/be/used/here
      - id
      - roles
      - osfinger
      - os
      - os_family
