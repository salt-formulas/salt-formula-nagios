{%- from "nagios/map.jinja" import server with context %}
{% if server.objects.contacts is mapping and server.objects.contacts.items()|length > 0 %}
nagios contact definitions:
  file.managed:
    - name: {{ server.objects_cfg_dir }}/{{ server.objects_file_prefix }}.contacts.cfg
    - contents: |
        # Managed by SaltStack
{% for contact_id, contact in server.objects.get('contacts', {}).items() %}
        # {{ contact_id }}
        define contact {
          alias "{{ contact.alias }}"
          contact_name {{ contact.get('contact_name', contact_id) }}
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
{% endfor %}

    - watch_in:
      - service: {{ server.service }}
{% else %}
purge nagios contact definitions:
  file.absent:
    - name: {{ server.objects_cfg_dir }}/{{ server.objects_file_prefix }}.contacts.cfg
    - watch_in:
      - service: {{ server.service }}
{% endif %}
