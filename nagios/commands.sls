{%- from "nagios/map.jinja" import server with context %}
{%- if server.enabled %}
include:
- nagios.server

{%- set commands = server.objects.get('commands', {}) %}

{% if commands.keys()|length > 0 %}
Nagios commands configurations:
  file.managed:
    - name: {{ server.objects_cfg_dir }}/{{ server.objects_file_prefix }}.commands.cfg
    - template: jinja
    - source: salt://nagios/files/commands.cfg
    - user: root
    - mode: 644
    - defaults:
      commands: {{ commands }}
    - watch_in:
      - service: {{ server.service }}
{% endif %}

{% endif %}
