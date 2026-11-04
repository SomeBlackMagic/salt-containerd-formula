# -*- coding: utf-8 -*-
# vim: ft=sls

{#- Get the `tplroot` from `tpldir` #}
{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import mapdata as containerd with context %}
{%- from tplroot ~ "/macros/artifact.jinja" import artifact with context %}

{%- if containerd.components.containerd.enabled %}
{{ artifact(
  'containerd',
  'tarball',
  {
    'containerd': 'bin/containerd',
    'containerd-shim-runc-v2': 'bin/containerd-shim-runc-v2',
    'ctr': 'bin/ctr',
  },
  containerd.paths.bin_dir,
) }}
{%- endif %}
