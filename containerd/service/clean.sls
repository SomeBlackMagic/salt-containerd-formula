# -*- coding: utf-8 -*-
# vim: ft=sls

{#- Get the `tplroot` from `tpldir` #}
{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import mapdata as containerd with context %}

containerd-service-clean-service-dead:
  service.dead:
    - name: {{ containerd.service.name }}
    - enable: False
