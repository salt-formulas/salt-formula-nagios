{%- from "nagios/map.jinja" import nagios with context %}
{%- if nagios.enabled %}
nagios-server-package:
  pkg.installed:
    - name: {{ nagios.package}}

nagios-service:
  service.running:
    - name: {{ nagios.service }}
    - enable: true
    - require:
      - pkg: nagios-server-package

nagios-cgi-username:
  webutil.user_exists:
    - name: {{ nagios.ui_username }}
    - password: {{ nagios.ui_password }}
    - htpasswd_file: {{ nagios.ui_htpasswd_file }}
    - options: d
    - force: true
{%- endif %}
