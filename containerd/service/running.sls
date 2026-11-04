# -*- coding: utf-8 -*-
# vim: ft=sls

{#- Get the `tplroot` from `tpldir` #}
{%- set tplroot = tpldir.split('/')[0] %}
{%- set sls_config_file = tplroot ~ '.config.file' %}
{%- set sls_service_unit = tplroot ~ '.service.unit' %}
{%- from tplroot ~ "/map.jinja" import mapdata as containerd with context %}

include:
  - {{ sls_config_file }}
  - {{ sls_service_unit }}

containerd-service-running-service-running:
  service.running:
    - name: {{ containerd.service.name }}
    - enable: True
    - require:
      - cmd: containerd-service-unit-daemon-reload
    - watch:
      - file: containerd-config-file-file-managed
      - file: containerd-service-unit-file-managed
      - file: containerd-service-unit-dropin-file-managed
