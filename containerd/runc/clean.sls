# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import mapdata as settings with context %}

include:
  - {{ tplroot }}.service.clean

containerd-runc-clean-symlink-absent:
  file.absent:
    - name: {{ (settings.paths.sbin_dir ~ '/runc') | json }}
    - require:
      - sls: {{ tplroot }}.service.clean

containerd-runc-clean-version-directory-absent:
  file.absent:
    - name: {{ (settings.paths.prefix ~ '/runc') | json }}
    - require:
      - file: containerd-runc-clean-symlink-absent
