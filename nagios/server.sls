{%- from "nagios/map.jinja" import server with context %}
{%- if server.enabled %}
nagios-server-package:
  pkg.installed:
    - name: {{ server.package}}

{% if server.cgi_package %}
nagios-cgi-server-package:
  pkg.installed:
    - name: {{ server.cgi_package}}
{% endif %}

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

nagios-cgi-config:
  file.managed:
    - name: {{ server.cgi_conf }}
    - source: salt://nagios/files/cgi.cfg
    - template: jinja
    - require:
{% if server.cgi_package %}
      - pkg: nagios-cgi-server-package
{% else %}
      - pkg: nagios-server-package
{% endif %}

nagios-server-config:
  file.managed:
    - name: {{ server.conf }}
    - source: salt://nagios/files/nagios.cfg
    - template: jinja
    - watch_in:
      - service: {{ server.service }}

{% for cfg_dir in server.get('cfg_dir', []) -%}
{{cfg_dir}} config nagios dir:
  file.directory:
    - name: {{ cfg_dir }}
    - user: nagios
    - group: nagios
    - mode: 755
    - makedirs: True
    - require:
      - pkg: nagios-server-package
    - watch_in:
      - service: {{ server.service }}
{% endfor -%}

{%- endif %}
