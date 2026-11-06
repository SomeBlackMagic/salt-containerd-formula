# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import mapdata as settings with context %}

include:
  - {{ tplroot }}.service.clean

containerd-nerdctl-clean-config-absent:
  file.absent:
    - name: /etc/nerdctl/nerdctl.toml
    - require:
      - sls: {{ tplroot }}.service.clean

containerd-nerdctl-clean-symlink-absent:
  file.absent:
    - name: {{ (settings.paths.bin_dir ~ '/nerdctl') | json }}
    - require:
      - sls: {{ tplroot }}.service.clean

containerd-nerdctl-clean-version-directory-absent:
  file.absent:
    - name: {{ (settings.paths.prefix ~ '/nerdctl') | json }}
    - require:
      - file: containerd-nerdctl-clean-symlink-absent
