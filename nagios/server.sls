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

{% if ui.basic_auth is defined and ui.basic_auth.password is defined %}
nagios-cgi-username:
  webutil.user_exists:
    - name: {{ ui.basic_auth.get('username', 'nagiosadmin') }}
    - password: {{ ui.basic_auth.password }}
    - htpasswd_file: {{ ui.htpasswd_file }}
    - options: d
    - force: true
{% else %}
remove-basic_htpasswd_file:
  file.absent:
    - name: {{ ui.htpasswd_file }}
{% endif %}

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

{# Apache2 is installed by dependency, just configure it! #}
apache_services:
  service.running:
  - name: {{ ui.apache_service }}
  - enable: true
  - watch:
    - file: nagios_apache_config

nagios_apache_config:
 file.managed:
 - name: {{ ui.apache_config }}
 - source: salt://nagios/files/nagios.conf.{{ grains.os_family }}
 - template: jinja
 - mode: 644
 - user: root
 - group: root

{% else %} {% if ui.package %}
remove-nagios-cgi-server-package:
  pkg.removed:
    - name: {{ ui.package}}
{% endif %}
{% endif %} {# ui enabled #}

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
