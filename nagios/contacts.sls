{%- from "nagios/map.jinja" import server with context %}
{% for contact_id, contact in server.objects.get('contacts', {}).items() %}
{{ contact_id }} contact definition:
  file.managed:
    - name: {{ server.objects_cfg_dir }}/{{ server.objects_file_prefix }}.contact_{{ contact_id }}.cfg
    - contents: |
        # Managed by SaltStack
        define contact {
          alias "{{ contact.alias }}"
          contact_name {{ contact.contact_name }}
          contactgroups {{ contact.contactgroups|join(',')}}
          email {{ contact.email}}
          host_notification_commands {{ contact.get('host_notification_commands', server.default_host_notification_command) }}
          host_notification_options {{ contact.get('host_notification_options', 'd,r') }}
          host_notification_period {{ contact.get('host_notification_period', '24x7') }}
          host_notifications_enabled {{ contact.get('host_notifications_enabled', 1) }}
          service_notification_commands {{ contact.get('service_notification_commands', server.default_service_notification_command) }}
          service_notification_options {{ contact.get('service_notification_options', 'w,u,c,r') }}
          service_notification_period {{ contact.get('service_notification_period', '24x7') }}
          service_notifications_enabled {{ contact.get('service_notifications_enabled', 1) }}
        }

    - watch_in:
      - service: {{ server.service }}

{% endfor %}
