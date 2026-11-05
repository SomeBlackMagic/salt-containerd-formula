# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- set sls_package_install = tplroot ~ '.package.install' %}
{%- from tplroot ~ "/map.jinja" import mapdata as containerd with context %}

include:
  - {{ sls_package_install }}

{%- for name, config in containerd.config_d | dictsort %}
containerd-config-dropins-{{ loop.index }}-file-managed:
  file.serialize:
    - name: {{ containerd.paths.config_dir }}/conf.d/{{ name }}.toml
    - serializer: containerd_toml
    - dataset: {{ config | json }}
    - serializer_opts:
      - header: Managed by Salt, do not edit by hand
    - mode: '0644'
    - user: root
    - group: {{ containerd.rootgroup }}
    - makedirs: True
    - require:
      - sls: {{ sls_package_install }}
{%- endfor %}

containerd-config-dropins-directory-clean:
  file.directory:
    - name: {{ containerd.paths.config_dir }}/conf.d
    - user: root
    - group: {{ containerd.rootgroup }}
    - mode: '0755'
    - makedirs: True
    - clean: True
    - require:
      - sls: {{ sls_package_install }}
{%- for name, config in containerd.config_d | dictsort %}
      - file: containerd-config-dropins-{{ loop.index }}-file-managed
{%- endfor %}
