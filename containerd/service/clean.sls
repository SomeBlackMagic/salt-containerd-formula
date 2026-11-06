# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import mapdata as settings with context %}

containerd-service-clean-service-dead:
  service.dead:
    - name: {{ settings.service.name | json }}
    - enable: False

containerd-service-clean-dropin-absent:
  file.absent:
    - name: {{ ('/etc/systemd/system/' ~ settings.service.name ~ '.service.d/override.conf') | json }}
    - require:
      - service: containerd-service-clean-service-dead

containerd-service-clean-unit-absent:
  file.absent:
    - name: {{ ('/etc/systemd/system/' ~ settings.service.name ~ '.service') | json }}
    - require:
      - service: containerd-service-clean-service-dead

containerd-service-clean-daemon-reload:
  module.run:
    - service.systemctl_reload: []
    - onchanges:
      - file: containerd-service-clean-unit-absent
      - file: containerd-service-clean-dropin-absent
