# -*- coding: utf-8 -*-
# vim: ft=sls

{#- Get the `tplroot` from `tpldir` #}
{%- set tplroot = tpldir.split('/')[0] %}
{%- set sls_package_install = tplroot ~ '.package.install' %}
{%- from tplroot ~ "/map.jinja" import mapdata as containerd with context %}
{%- from tplroot ~ "/libtofs.jinja" import files_switch with context %}

include:
  - {{ sls_package_install }}

containerd-config-file-file-managed:
  file.managed:
    - name: {{ containerd.paths.config_dir }}/config.toml
    - source: {{ files_switch(['config.toml'], lookup='containerd-config-file-file-managed') }}
    - mode: '0644'
    - user: root
    - group: {{ containerd.rootgroup }}
    - makedirs: True
    - template: jinja
    - require:
      - sls: {{ sls_package_install }}
    - context:
        containerd: {{ containerd | json }}
