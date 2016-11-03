{%- from "nagios/map.jinja" import server with context %}
{%- if server.enabled %}

{%- set commands = server.objects.get('commands', {}) %}

{% if commands.keys()|length > 0 %}
Nagios commands configurations:
  file.managed:
    - name: {{ server.objects_cfg_dir }}/{{ server.objects_file_prefix }}.commands.cfg
    - template: jinja
    - user: root
    - mode: 644
    - contents: |
{% for cmd_id, conf in commands.items() %}
        define command {
{% if not conf.command_line[0] == '/' %}
          command_line {{server.plugin_dir }}/{{ conf.command_line }}
{% else %}
          command_line {{ conf.command_line }}
{% endif %}
          command_name {{ conf.command_name|default(cmd_id) }}
        }
{% endfor %}
    - watch_in:
      - service: {{ server.service }}
{% endif %}

{% endif %}
