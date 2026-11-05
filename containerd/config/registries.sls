# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import mapdata as containerd with context %}

{%- for host, registry in containerd.registries | dictsort %}
{%- set host_data = registry.copy() %}
{%- set files = host_data.pop('files', {}) %}
{%- set hosts = host_data.pop('hosts', {}) %}
{%- if hosts %}
{%- do host_data.update({'host': hosts}) %}
{%- endif %}
{%- set directory = containerd.paths.certs_dir ~ '/' ~ host %}

containerd-config-registries-{{ loop.index }}-hosts-file:
  file.serialize:
    - name: {{ (directory ~ '/hosts.toml') | json }}
    - serializer: containerd_toml
    - dataset: {{ host_data | json }}
    - serializer_opts:
      - header: Managed by Salt, do not edit by hand
    - user: root
    - group: {{ containerd.rootgroup }}
    - mode: '0644'
    - makedirs: True
    - show_changes: False

{%- set host_index = loop.index %}
{%- for filename, contents in files | dictsort %}
containerd-config-registries-{{ host_index }}-{{ loop.index }}-cert-file:
  file.managed:
    - name: {{ (directory ~ '/' ~ filename) | json }}
    - contents: {{ contents | json }}
    - user: root
    - group: {{ containerd.rootgroup }}
    - mode: '0644'
    - makedirs: True
    - show_changes: False
{%- endfor %}

containerd-config-registries-{{ host_index }}-directory-clean:
  file.directory:
    - name: {{ directory | json }}
    - user: root
    - group: {{ containerd.rootgroup }}
    - mode: '0755'
    - clean: True
    - require:
      - file: containerd-config-registries-{{ host_index }}-hosts-file
{%- for filename, contents in files | dictsort %}
      - file: containerd-config-registries-{{ host_index }}-{{ loop.index }}-cert-file
{%- endfor %}
{%- endfor %}

{%- if containerd.registries_purge %}
containerd-config-registries-directory-clean:
  file.directory:
    - name: {{ containerd.paths.certs_dir | json }}
    - user: root
    - group: {{ containerd.rootgroup }}
    - mode: '0755'
    - makedirs: True
    - clean: True
{%- if containerd.registries %}
    - require:
{%- for host, registry in containerd.registries | dictsort %}
      - file: containerd-config-registries-{{ loop.index }}-directory-clean
{%- endfor %}
{%- endif %}
{%- endif %}
