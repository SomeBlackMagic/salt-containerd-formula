# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import mapdata as containerd with context %}
{%- if containerd.kernel.enabled %}
{%- if salt['grains.get']('virtual') in ['container', 'Docker'] or salt['grains.get']('virtual_subtype') == 'Docker' %}
containerd-kernel-sysctl-file:
  file.managed:
    - name: /etc/sysctl.d/90-containerd.conf
    - user: root
    - group: {{ containerd.rootgroup }}
    - mode: '0644'
    - contents: |
{%- for key, value in containerd.kernel.sysctl.items() %}
        {{ key }} = {{ value }}
{%- endfor %}

{%- else %}
include:
  - .modules

{%- for key, value in containerd.kernel.sysctl.items() %}
containerd-kernel-sysctl-{{ loop.index }}:
  sysctl.present:
    - name: {{ key | json }}
    - value: {{ value | json }}
    - config: /etc/sysctl.d/90-containerd.conf
    - require:
      - sls: {{ tplroot }}.kernel.modules
{%- endfor %}
{%- endif %}
{%- endif %}
