{%- from "nagios/map.jinja" import server with context %}
{%- if server.enabled %}

{# configure user definied hosts #}
{%- set hosts = server.objects.get('hosts', {}) %}

nagios host configurations:
  file.managed:
    - name: {{ server.objects_cfg_dir }}/{{ server.objects_file_prefix }}.hosts.cfg
    - source: salt://nagios/files/hosts.cfg
    - template: jinja
    - user: root
    - mode: 644
    - defaults:
      hosts: {{ hosts }}
    - watch_in:
      - service: {{ server.service }}
{%- endif %}
