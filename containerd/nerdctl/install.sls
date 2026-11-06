# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import mapdata as settings with context %}
{%- from tplroot ~ '/macros/artifact.jinja' import artifact with context %}

{%- if settings.components.nerdctl.enabled %}
include:
  - {{ tplroot }}.preflight

{{ artifact('nerdctl', 'tarball', {'nerdctl': 'nerdctl'}, settings.paths.bin_dir) }}
{%- endif %}
