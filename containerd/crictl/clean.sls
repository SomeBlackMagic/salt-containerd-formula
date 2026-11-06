# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import mapdata as settings with context %}

containerd-crictl-clean-config:
  file.absent:
    - name: /etc/crictl.yaml

containerd-crictl-clean-symlink:
  file.absent:
    - name: {{ settings.paths.bin_dir }}/crictl

containerd-crictl-clean-version-directory:
  file.absent:
    - name: {{ settings.paths.prefix }}/crictl/{{ settings.components.crictl.version }}
    - require:
      - file: containerd-crictl-clean-symlink
