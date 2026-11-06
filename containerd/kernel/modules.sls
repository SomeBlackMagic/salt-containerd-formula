# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import mapdata as containerd with context %}
{%- if containerd.kernel.enabled %}
containerd-kernel-modules-file:
  file.managed:
    - name: /etc/modules-load.d/containerd.conf
    - user: root
    - group: {{ containerd.rootgroup }}
    - mode: '0644'
    - contents: |
{%- for module in containerd.kernel.modules %}
        {{ module }}
{%- endfor %}

{%- if salt['grains.get']('virtual') not in ['container', 'Docker'] and salt['grains.get']('virtual_subtype') != 'Docker' %}
{%- for module in containerd.kernel.modules %}
containerd-kernel-module-{{ loop.index }}:
  kmod.present:
    - name: {{ module | json }}
    - require:
      - file: containerd-kernel-modules-file
{%- endfor %}
{%- endif %}
{%- endif %}
