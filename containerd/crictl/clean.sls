# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import mapdata as settings with context %}

include:
  - {{ tplroot }}.service.clean

containerd-crictl-clean-config-absent:
  file.absent:
    - name: /etc/crictl.yaml
    - require:
      - sls: {{ tplroot }}.service.clean

containerd-crictl-clean-symlink-absent:
  file.absent:
    - name: {{ (settings.paths.bin_dir ~ '/crictl') | json }}
    - require:
      - sls: {{ tplroot }}.service.clean

containerd-crictl-clean-version-directory-absent:
  file.absent:
    - name: {{ (settings.paths.prefix ~ '/crictl') | json }}
    - require:
      - file: containerd-crictl-clean-symlink-absent
