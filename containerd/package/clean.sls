# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import mapdata as settings with context %}

include:
  - {{ tplroot }}.config.clean

{%- for name in ['containerd', 'containerd-shim-runc-v2', 'ctr'] %}
containerd-package-clean-{{ name }}-symlink-absent:
  file.absent:
    - name: {{ (settings.paths.bin_dir ~ '/' ~ name) | json }}
    - require:
      - sls: {{ tplroot }}.config.clean
{%- endfor %}

containerd-package-clean-version-directory-absent:
  file.absent:
    - name: {{ (settings.paths.prefix ~ '/containerd') | json }}
    - require:
{%- for name in ['containerd', 'containerd-shim-runc-v2', 'ctr'] %}
      - file: containerd-package-clean-{{ name }}-symlink-absent
{%- endfor %}
