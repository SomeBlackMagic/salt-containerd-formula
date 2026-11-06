# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import mapdata as settings with context %}

include:
  - {{ tplroot }}.service.clean

containerd-config-clean-file-absent:
  file.absent:
    - name: {{ (settings.paths.config_dir ~ '/config.toml') | json }}
    - require:
      - sls: {{ tplroot }}.service.clean

containerd-config-clean-dropins-absent:
  file.absent:
    - name: {{ (settings.paths.config_dir ~ '/conf.d') | json }}
    - require:
      - sls: {{ tplroot }}.service.clean

{%- for host, registry in settings.registries | dictsort %}
containerd-config-clean-registry-{{ loop.index }}-absent:
  file.absent:
    - name: {{ (settings.paths.certs_dir ~ '/' ~ host) | json }}
    - require:
      - sls: {{ tplroot }}.service.clean
{%- endfor %}
