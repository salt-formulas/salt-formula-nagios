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
{%- endif %}
