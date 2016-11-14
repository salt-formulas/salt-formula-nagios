{%- from "nagios/map.jinja" import server with context %}
{%- if server.enabled %}
{% if server.objects.contactgroups is mapping and server.objects.contactgroups.items()|length > 0 %}
include:
- nagios.server

nagios contactgroup definitions:
  file.managed:
    - name: {{ server.objects_cfg_dir }}/{{ server.objects_file_prefix }}.contactgroups.cfg
    - contents: |
        # Managed by SaltStack
{% for group_id, group in server.objects.get('contactgroups', {}).items() %}
        # {{ group_id }}
        define contactgroup {
          contactgroup_name {{ group.contactgroup_name }}
        }
{% endfor %}

    - watch_in:
      - service: {{ server.service }}
{% else %}
purge nagios contactgroup definitions:
  file.absent:
    - name: {{ server.objects_cfg_dir }}/{{ server.objects_file_prefix }}.contactgroups.cfg
    - watch_in:
      - service: {{ server.service }}
{% endif %}
{% endif %}
