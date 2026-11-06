# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import mapdata as settings with context %}

containerd-nerdctl-clean-config:
  file.absent:
    - name: /etc/nerdctl/nerdctl.toml

containerd-nerdctl-clean-symlink:
  file.absent:
    - name: {{ settings.paths.bin_dir }}/nerdctl

containerd-nerdctl-clean-version-directory:
  file.absent:
    - name: {{ settings.paths.prefix }}/nerdctl/{{ settings.components.nerdctl.version }}
    - require:
      - file: containerd-nerdctl-clean-symlink
