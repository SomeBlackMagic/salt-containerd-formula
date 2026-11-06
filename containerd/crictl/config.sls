# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import mapdata as settings with context %}

{%- if settings.components.crictl.enabled %}
include:
  - .install

containerd-crictl-config-file:
  file.serialize:
    - name: /etc/crictl.yaml
    - serializer: yaml
    - dataset: {{ settings.components.crictl.config | json }}
    - user: root
    - group: {{ settings.rootgroup | json }}
    - mode: '0644'
    - require:
      - file: containerd-artifact-crictl-crictl-symlink
{%- endif %}
