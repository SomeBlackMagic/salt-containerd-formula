# -*- coding: utf-8 -*-
# vim: ft=yaml
---
containerd:
  registries:
    docker.io:
      server: https://registry-1.docker.io
      hosts:
        https://mirror.example.com:
          capabilities: [pull, resolve]
          ca: ca.crt
      files:
        ca.crt: |
          -----BEGIN CERTIFICATE-----
          test-ca-only
          -----END CERTIFICATE-----
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
