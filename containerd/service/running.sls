# -*- coding: utf-8 -*-
# vim: ft=sls

{#- Get the `tplroot` from `tpldir` #}
{%- set tplroot = tpldir.split('/')[0] %}
{%- set sls_config_file = tplroot ~ '.config.file' %}
{%- set sls_config_dropins = tplroot ~ '.config.dropins' %}
{%- set sls_service_unit = tplroot ~ '.service.unit' %}
{%- from tplroot ~ "/map.jinja" import mapdata as containerd with context %}
{%- set change_requisite = 'watch' if containerd.service.restart_on_change else 'require' %}

include:
  - {{ sls_config_file }}
  - {{ sls_config_dropins }}
  - {{ sls_service_unit }}

{%- if containerd.service.state == 'running' %}
containerd-service-running-service-running:
  service.running:
    - name: {{ containerd.service.name }}
    - enable: True
    - {{ change_requisite }}:
      - archive: containerd-artifact-containerd-tarball
      - file: containerd-artifact-containerd-containerd-symlink
      - file: containerd-config-file-file-managed
      - file: containerd-config-dropins-directory-clean
      - file: containerd-service-unit-file-managed
      - file: containerd-service-unit-dropin-file-managed
{%- if containerd.service.restart_on_change %}
    - require:
{%- endif %}
      - cmd: containerd-service-unit-daemon-reload
{%- elif containerd.service.state == 'enabled' %}
containerd-service-running-service-enabled:
  service.enabled:
    - name: {{ containerd.service.name }}
    - require:
      - cmd: containerd-service-unit-daemon-reload
      - file: containerd-config-file-file-managed
      - file: containerd-config-dropins-directory-clean
{%- else %}
{{ raise("Unsupported service.state: '{}'".format(containerd.service.state)) }}
{%- endif %}
