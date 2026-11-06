# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import mapdata as settings with context %}

include:
  - {{ tplroot }}.service.clean

{%- for name in ['bridge', 'loopback', 'host-local'] %}
containerd-cni-clean-{{ name }}-symlink-absent:
  file.absent:
    - name: {{ (settings.components.cni.dir ~ '/' ~ name) | json }}
    - require:
      - sls: {{ tplroot }}.service.clean
{%- endfor %}

containerd-cni-clean-version-directory-absent:
  file.absent:
    - name: {{ (settings.paths.prefix ~ '/cni') | json }}
    - require:
{%- for name in ['bridge', 'loopback', 'host-local'] %}
      - file: containerd-cni-clean-{{ name }}-symlink-absent
{%- endfor %}
