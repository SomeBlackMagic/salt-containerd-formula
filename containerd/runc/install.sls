# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import mapdata as settings with context %}
{%- from tplroot ~ '/macros/artifact.jinja' import artifact with context %}

{%- if settings.components.runc.enabled %}
include:
  - {{ tplroot }}.preflight

{{ artifact('runc', 'binary', {'runc': 'runc'}, settings.paths.sbin_dir) }}
{%- endif %}
