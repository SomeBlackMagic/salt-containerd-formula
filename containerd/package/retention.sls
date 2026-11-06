# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import mapdata as settings with context %}
{%- set keep = settings.keep_versions %}
{%- if keep is not number or keep is boolean or keep < 0 or keep != keep | int %}
{{ raise('keep_versions must be a non-negative integer') }}
{%- endif %}
{%- if settings.components.containerd.enabled %}
{%- set root = settings.paths.prefix ~ '/containerd' %}
{%- set current = root ~ '/' ~ settings.components.containerd.version %}
{%- set older = [] %}
{%- for path in salt['file.find'](root, type='d', name='[0-9]*', maxdepth=1) if path != current %}
{%-   set stats = salt['file.stats'](path, follow_symlinks=False) %}
{%-   if stats and stats.get('type') == 'dir' %}
{%-     do older.append({'path': path, 'mtime': stats.mtime}) %}
{%-   endif %}
{%- endfor %}
{%- for item in (older | sort(attribute='mtime', reverse=True))[keep:] %}
containerd-package-retention-{{ loop.index }}-absent:
  file.absent:
    - name: {{ item.path | json }}
    - require:
      - archive: containerd-artifact-containerd-tarball
{%- endfor %}
{%- endif %}
