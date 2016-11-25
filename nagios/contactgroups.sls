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

    {%- if server.automatic_starting %}
    - watch_in:
      - service: {{ server.service }}
    {%- endif %}
{% else %}
purge nagios contactgroup definitions:
  file.absent:
    - name: {{ server.objects_cfg_dir }}/{{ server.objects_file_prefix }}.contactgroups.cfg
    {%- if server.automatic_starting %}
    - watch_in:
      - service: {{ server.service }}
    {%- endif %}
{% endif %}
{% endif %}
