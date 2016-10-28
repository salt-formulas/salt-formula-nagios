{%- from "nagios/map.jinja" import server with context %}
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

