{%- from "nagios/map.jinja" import server with context %}
{%- if server.enabled %}
include:
- nagios.server

{%- set services = server.objects.get('services', {}) %}

{% if server.dynamic is mapping and server.dynamic.enabled %}
{% set grain_hostname = server.dynamic.get('grain_hostname', 'nodename') %}
{% if server.dynamic.services is iterable and server.dynamic.services|length > 0 %}

{% for conf in server.dynamic.services %}
{% set rowloop = loop %}
{% for host_name, grains in salt['mine.get'](conf.get('target', '*'), 'grains.items', conf.get('expr_from', 'compound')).items() %}

{% set name = conf.get('service_description', conf.get('name', '{}_check_{}'.format(host_name, rowloop.index))) %}
{% do salt['grains.filter_by']({'default': services},
  merge={
    grains[grain_hostname]+name: conf,
  })
%}

{% do salt['grains.filter_by']({'default': services},
  merge={
    grains[grain_hostname]+name: {
      'host_name': grains[grain_hostname],
      'service_description': name,
    }
  })
%}
{% endfor %}

{% endfor %}

{% endif %}
{% endif %}

nagios service configurations:
  file.managed:
    - name: {{ server.objects_cfg_dir }}/{{ server.objects_file_prefix }}.services.cfg
    - source: salt://nagios/files/services.cfg
    - template: jinja
    - user: root
    - mode: 644
    - defaults:
      services: {{ services|yaml }}
    - watch_in:
      - service: {{ server.service }}
{%- endif %}
