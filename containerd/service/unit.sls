# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import mapdata as containerd with context %}
{%- from tplroot ~ '/libtofs.jinja' import files_switch with context %}

include:
  - {{ tplroot }}.package.install

containerd-service-unit-file-managed:
  file.managed:
    - name: /etc/systemd/system/{{ containerd.service.name }}.service
    - source: {{ files_switch(['containerd.service.jinja'], lookup='containerd-service-unit-file-managed') }}
    - template: jinja
    - context:
        containerd: {{ containerd | json }}
    - user: root
    - group: {{ containerd.rootgroup }}
    - mode: '0644'
    - require:
      - sls: {{ tplroot }}.package.install

containerd-service-unit-dropin-file-managed:
  file.managed:
    - name: /etc/systemd/system/{{ containerd.service.name }}.service.d/override.conf
    - source: {{ files_switch(['override.conf.jinja'], lookup='containerd-service-unit-dropin-file-managed') }}
    - template: jinja
    - context:
        containerd: {{ containerd | json }}
    - user: root
    - group: {{ containerd.rootgroup }}
    - mode: '0644'
    - makedirs: True
    - show_changes: False
    - require:
      - file: containerd-service-unit-file-managed

containerd-service-unit-daemon-reload:
  cmd.run:
    - name: systemctl daemon-reload
    - onchanges:
      - file: containerd-service-unit-file-managed
      - file: containerd-service-unit-dropin-file-managed
