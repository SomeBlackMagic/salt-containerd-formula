# -*- coding: utf-8 -*-
# vim: ft=sls

# Cleanup is explicit and ordered by requisites in the component states.
include:
  - .service.clean
  - .config.clean
  - .package.clean
  - .runc.clean
  - .cni.clean
  - .crictl.clean
  - .nerdctl.clean
  - .kernel.clean

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import mapdata as settings with context %}
{%- if settings.clean.purge_data %}
containerd-clean-data-directory-absent:
  file.absent:
    - name: /var/lib/containerd
    - require:
      - sls: {{ tplroot }}.service.clean
{%- endif %}
