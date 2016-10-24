{%- from "nagios/map.jinja" import server with context %}
{%- if server.enabled %}
nagios-server-package:
  pkg.installed:
    - name: {{ server.package}}

nagios-service:
  service.running:
    - name: {{ server.service }}
    - enable: true
    - require:
      - pkg: nagios-server-package

nagios-cgi-username:
  webutil.user_exists:
    - name: {{ server.ui_username }}
    - password: {{ server.ui_password }}
    - htpasswd_file: {{ server.ui_htpasswd_file }}
    - options: d
    - force: true

nagios-server-config:
  file.managed:
    - name: {{ server.conf }}
    - source: salt://nagios/files/nagios.cfg
    - template: jinja
    - watch_in:
      - service: {{ server.service }}
{%- endif %}
