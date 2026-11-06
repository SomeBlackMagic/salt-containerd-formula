# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import mapdata as containerd with context %}
{%- if containerd.kernel.enabled %}
include:
  - .modules
  - .sysctl
{%- endif %}
