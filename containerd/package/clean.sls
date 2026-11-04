# -*- coding: utf-8 -*-
# vim: ft=sls

{#- Get the `tplroot` from `tpldir` #}
{%- set tplroot = tpldir.split('/')[0] %}
{%- set sls_config_clean = tplroot ~ '.config.clean' %}
{%- from tplroot ~ "/map.jinja" import mapdata as containerd with context %}

include:
  - {{ sls_config_clean }}

{%- for name in ['containerd', 'containerd-shim-runc-v2', 'ctr'] %}
containerd-package-clean-{{ name }}-symlink-absent:
  file.absent:
    - name: {{ containerd.paths.bin_dir }}/{{ name }}
    - require:
      - sls: {{ sls_config_clean }}
{%- endfor %}

containerd-package-clean-version-directory-absent:
  file.absent:
    - name: {{ containerd.paths.prefix }}/containerd/{{ containerd.components.containerd.version }}
    - require:
{%- for name in ['containerd', 'containerd-shim-runc-v2', 'ctr'] %}
      - file: containerd-package-clean-{{ name }}-symlink-absent
{%- endfor %}
    - require:
      - sls: {{ sls_config_clean }}
