# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import mapdata as settings with context %}

{%- if settings.components.nerdctl.enabled %}
include:
  - .install

containerd-nerdctl-config-file:
  file.serialize:
    - name: /etc/nerdctl/nerdctl.toml
    - serializer: containerd_toml
    - dataset: {{ settings.components.nerdctl.config | json }}
    - serializer_opts:
      - header: Managed by Salt, do not edit by hand
    - user: root
    - group: {{ settings.rootgroup | json }}
    - mode: '0644'
    - makedirs: True
    - require:
      - file: containerd-artifact-nerdctl-nerdctl-symlink
{%- endif %}
