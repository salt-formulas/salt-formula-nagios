{%- from "nagios/map.jinja" import server with context %}
{% for group_id, group in server.objects.get('contactgroups', {}).items() %}
{{ group_id }} contactgroup definition:
  file.managed:
    - name: {{ server.objects_cfg_dir }}/{{ server.objects_file_prefix }}.contactgroups_{{ group_id }}.cfg
    - contents: |
        # Managed by SaltStack
        define contactgroup {
          contactgroup_name {{ group.contactgroup_name }}
        }

    - watch_in:
      - service: {{ server.service }}

{% endfor %}
