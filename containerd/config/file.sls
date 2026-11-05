# -*- coding: utf-8 -*-
# vim: ft=sls

{#- Get the `tplroot` from `tpldir` #}
{%- set tplroot = tpldir.split('/')[0] %}
{%- set sls_package_install = tplroot ~ '.package.install' %}
{%- from tplroot ~ "/map.jinja" import mapdata as containerd with context %}

include:
  - {{ sls_package_install }}

containerd-config-file-file-managed:
  file.serialize:
    - name: {{ containerd.paths.config_dir }}/config.toml
    - serializer: containerd_toml
    - dataset: {{ containerd.config | json }}
    - serializer_opts:
      - header: Managed by Salt, do not edit by hand
    - mode: '0644'
    - user: root
    - group: {{ containerd.rootgroup }}
    - makedirs: True
    - require:
      - sls: {{ sls_package_install }}
