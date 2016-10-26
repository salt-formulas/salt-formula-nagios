{%- from "nagios/map.jinja" import server with context %}
{%- from "nagios/map.jinja" import ui with context %}
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

{% if ui.enabled is defined and ui.enabled %}
{% if ui.package %}
nagios-cgi-server-package:
  pkg.installed:
    - name: {{ ui.package}}
{% endif %}

nagios-cgi-username:
  webutil.user_exists:
    - name: {{ ui.username }}
    - password: {{ ui.password }}
    - htpasswd_file: {{ ui.htpasswd_file }}
    - options: d
    - force: true

nagios-cgi-config:
  file.managed:
    - name: {{ ui.cgi_conf }}
    - source: salt://nagios/files/cgi.cfg
    - template: jinja
    - require:
{% if server.cgi_package %}
      - pkg: nagios-cgi-server-package
{% else %}
      - pkg: nagios-server-package
{% endif %}

{% else %}
{% if ui.package %}
nagios-cgi-server-package:
  pkg.removed:
    - name: {{ ui.package}}
{% endif %}
{% endif %} {# cgi enabled #}

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
