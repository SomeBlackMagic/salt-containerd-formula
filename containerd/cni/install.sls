# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import mapdata as settings with context %}
{%- from tplroot ~ '/macros/artifact.jinja' import artifact with context %}

{%- if settings.components.cni.enabled %}
include:
  - {{ tplroot }}.preflight

{{ artifact('cni', 'tarball', {'bridge': 'bridge', 'loopback': 'loopback', 'host-local': 'host-local'}, settings.components.cni.dir) }}
{%- endif %}
