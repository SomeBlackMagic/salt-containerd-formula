# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import mapdata as containerd with context %}
{%- set arch = containerd.get('arch') %}

containerd-preflight-architecture:
{%- if arch in ['amd64', 'arm64'] %}
  test.nop:
    - name: {{ ('Supported architecture: ' ~ arch) | json }}
{%- else %}
  test.fail_without_changes:
    - name: {{ ('Unsupported architecture: ' ~ (arch | string) ~ ' (expected amd64 or arm64)') | json }}
{%- endif %}

{%- if containerd.conflicts.remove %}
containerd-preflight-remove-conflicts:
  pkg.removed:
    - name: containerd-conflicting-packages
    - pkgs: {{ containerd.conflicts.packages | json }}
    - require:
      - test: containerd-preflight-architecture
{%- else %}
{%- set installed = salt['pkg.list_pkgs']() %}
{%- set conflicts = [] %}
{%- for package in containerd.conflicts.packages %}
{%-   if package in installed %}
{%-     do conflicts.append(package) %}
{%-   endif %}
{%- endfor %}
containerd-preflight-conflicts:
{%- if conflicts %}
  test.fail_without_changes:
    - name: {{ ('Conflicting packages are installed: ' ~ conflicts | join(', ') ~ '. Set containerd:conflicts:remove to true to remove them.') | json }}
{%- else %}
  test.nop:
    - name: No conflicting packages are installed
{%- endif %}
    - require:
      - test: containerd-preflight-architecture
{%- endif %}
