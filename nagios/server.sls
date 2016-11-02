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

{% if server.ui.enabled is defined and server.ui.enabled %}
{% if server.ui.package %}
nagios-cgi-server-package:
  pkg.installed:
    - name: {{ server.ui.package}}
{% endif %}

{% if server.ui.basic_auth is defined and server.ui.basic_auth.password is defined %}
nagios-cgi-username:
  webutil.user_exists:
    - name: {{ server.ui.basic_auth.get('username', 'nagiosadmin') }}
    - password: {{ server.ui.basic_auth.password }}
    - htpasswd_file: {{ server.ui.htpasswd_file }}
    - options: d
    - force: true
{% else %}
remove-basic_htpasswd_file:
  file.absent:
    - name: {{ server.ui.htpasswd_file }}
{% endif %}

nagios-cgi-config:
  file.managed:
    - name: {{ server.ui.cgi_conf }}
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
  - name: {{ server.ui.apache_service }}
  - enable: true
  - watch:
    - file: nagios_apache_config

nagios_apache_config:
 file.managed:
 - name: {{ server.ui.apache_config }}
 - source: salt://nagios/files/nagios.conf.{{ grains.os_family }}
 - template: jinja
 - mode: 644
 - user: root
 - group: root

{% else %} {% if server.ui.package %}
remove-nagios-cgi-server-package:
  pkg.removed:
    - name: {{ server.ui.package}}
{% endif %}
{% endif %} {# ui enabled #}

nagios-server-config:
  file.managed:
    - name: {{ server.conf }}
    - source: salt://nagios/files/nagios.cfg
    - template: jinja
    - watch_in:
      - service: {{ server.service }}

{% if salt['grains.get']('os_family') == 'Debian' %}
{#
Fix a permission issue with Ubuntu to allow using external commands
through the web UI
#}

{{ server.ui.apache_user }}:
  user.present:
    - optional_groups:
      - nagios
    - remove_groups: False
    - watch_in:
      - service: {{ server.ui.apache_service }}

{{ server.command_dir }}:
  file.directory:
    - user: nagios
    - group: {{ server.ui.apache_user }}
    - dir_mode: 0760
    - file_mode: 0760
    - recurse:
      - user
      - group
      - mode
    - require:
      - pkg: nagios-server-package
    - watch_in:
      - service: {{ server.ui.apache_service }}
      - service: {{ server.service }}
{% endif %}
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

{# Configure commands to send notification by SMTP #}

{% if server.additional_packages is iterable %}
additional packages:
  pkg.installed:
    - names: {{ server.additional_packages }}
{% endif %}

notification_by_smtp_for_services:
  file.managed:
    - name: {{ server.objects_cfg_dir}}/cmd-notify-service-smtp.cfg
    - source: salt://nagios/files/cmd-notify-service-smtp.cfg
    - template: jinja
    - watch_in:
      - service: {{ server.service }}

notification_by_smtp_for_hosts:
  file.managed:
    - name: {{ server.objects_cfg_dir}}/cmd-notify-host-smtp.cfg
    - source: salt://nagios/files/cmd-notify-host-smtp.cfg
    - template: jinja
    - watch_in:
      - service: {{ server.service }}

{%- endif %}
