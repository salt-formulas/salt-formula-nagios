{%- from "nagios/map.jinja" import server with context %}
{%- if server.enabled %}
nagios_server_package:
  pkg.installed:
  - names: {{ server.package }}


{%- if server.automatic_starting %}
nagios_service:
  service.running:
    - name: {{ server.service }}
    - enable: true
    - require:
      - pkg: nagios_server_package
    - watch:
      - file: {{ server.conf }}
      - file: {{ server.objects_cfg_dir }}/*
{%- else %}
nagios_service:
  service.disabled:
    - name: {{ server.service }}
{% endif %}

{% if server.ui.enabled is defined and server.ui.enabled %}
{% if server.ui.package %}
nagios_cgi_server_package:
  pkg.installed:
    - name: {{ server.ui.package}}
{% endif %}

{% if server.ui.auth.basic is defined and server.ui.auth.basic.password is defined %}
nagios_cgi_username:
  webutil.user_exists:
    - name: {{ server.ui.auth.basic.get('username', 'nagiosadmin') }}
    - password: {{ server.ui.auth.basic.password }}
    - htpasswd_file: {{ server.ui.htpasswd_file }}
    - options: d
    - force: true
{% else %}
remove_basic_htpasswd_file:
  file.absent:
    - name: {{ server.ui.htpasswd_file }}
{% endif %}

nagios_cgi_config:
  file.managed:
    - name: {{ server.ui.cgi_conf }}
    - source: salt://nagios/files/cgi.cfg
    - template: jinja
    - require:
{% if server.cgi_package %}
      - pkg: nagios_cgi_server_package
{% else %}
      - pkg: nagios_server_package
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

nagios_apache_wsgi_config:
  file.managed:
    - name: {{ server.ui.wsgi.apache_conf_dir }}/nagios_wsgi.conf
    - template: jinja
    - mode: 644
    - user: root
    - group: root
    - contents: |
        Listen {{ server.ui.wsgi.port }}
    - watch_in:
      - service: {{ server.ui.apache_service }}

{{ server.ui.wsgi.script_path }}:
  file.managed:
    - source: salt://nagios/files/process-service-checks.wsgi
    - user: nagios
    - group: nagios
    - mode: 555

nagios_apache_wsgi_site:
  file.managed:
    - name: {{ server.ui.wsgi.apache_sites_dir }}/nagios_wsgi.conf
    - source: salt://nagios/files/nagios_wsgi.conf.{{ grains.os_family }}
    - template: jinja
    - mode: 644
    - user: root
    - group: root
    - require:
      - file: {{ server.ui.wsgi.script_path }}
    - watch_in:
      - service: {{ server.ui.apache_service }}

wsgi_pkg:
  pkg.installed:
    - names: {{ server.ui.wsgi.pkg }}
    - watch_in:
      - service: {{ server.ui.apache_service }}

{%- if server.ui.auth.ldap.enabled %}
{% for mod in ('ldap', 'authnz_ldap') %}
enable_apache_{{ mod }}_module:
  apache_module.enable:
    - name: {{ mod }}
    - watch_in:
      - service: {{ server.ui.apache_service }}
{% endfor %}
{%- endif %}

enable_apache_wsgi_module:
  apache_module.enable:
    - name: wsgi
    - require:
      - pkg: wsgi_pkg
    - watch_in:
      - service: {{ server.ui.apache_service }}

enable Nagios WSGI conf:
  apache_conf.enable:
    - name: nagios_wsgi
    - require:
      - file: nagios_apache_wsgi_config
    - watch_in:
      - service: {{ server.ui.apache_service }}

enable Nagios WSGI app:
  apache_site.enable:
    - name: nagios_wsgi
    - require:
      - apache_module: enable_apache_wsgi_module
      - apache_conf: enable Nagios WSGI conf
      - file: nagios_apache_wsgi_site
    - watch_in:
      - service: {{ server.ui.apache_service }}

{%- endif %}

{% else %} {% if server.ui.package %}
remove_nagios_cgi_server_package:
  pkg.removed:
    - name: {{ server.ui.package}}
{% endif %}
{% endif %} {# ui enabled #}

nagios_server_config:
  file.managed:
    - name: {{ server.conf }}
    - source: salt://nagios/files/nagios.cfg
    - template: jinja

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
    - dir_mode: 0750
    - require:
      - pkg: nagios_server_package
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
      - pkg: nagios_server_package
{% endfor -%}

{% if server.purge_distribution_config is defined and server.purge_distribution_config %}
{% for to_purge in server.get('configs_to_purge', []) %}
purge {{ to_purge }}:
  file.absent:
    - name: {{ to_purge }}
{% endfor %}
{% endif %}

{# Configure commands to send notification by SMTP #}

{% if server.additional_packages is iterable %}
additional packages:
  pkg.installed:
    - names: {{ server.additional_packages }}
{% endif %}

{%- if server.notification is defined %}
{%- if server.notification.smtp is defined %}
notification_by_smtp_for_services:
  file.managed:
    - name: {{ server.objects_cfg_dir}}/cmd-notify-service-smtp.cfg
    - source: salt://nagios/files/cmd-notify-service-smtp.cfg
    - template: jinja

notification_by_smtp_for_hosts:
  file.managed:
    - name: {{ server.objects_cfg_dir}}/cmd-notify-host-smtp.cfg
    - source: salt://nagios/files/cmd-notify-host-smtp.cfg
    - template: jinja
{%- endif %}

{%- if server.notification.sfdc is defined and server.notification.sfdc.get('enabled', false) %}
{%- set sfdc_params = {
    'log_file': server.log_dir + '/sfdc_nagios.log',
    'salesforce_module': server.handler_dir + '/sfdc/salesforce.py',
    'sfdc_plugin': server.handler_dir + '/sfdc/sfdc_nagios.py',
    'sfdc_config_file': server.conf_dir + '/sfdc_nagios.yaml',
    'token_cache_file': server.pid_dir + '/sfdc_token_cache',
} %}
{%- do sfdc_params.update(server.notification.sfdc) %}
notification_sfdc_module:
  file.managed:
    - name: {{ sfdc_params.salesforce_module }}
    - source: salt://nagios/files/handlers/sfdc/salesforce.py
    - makedirs: True
    - mode: 644

notification_sfdc_plugin:
  file.managed:
    - name: {{ sfdc_params.sfdc_plugin }}
    - source: salt://nagios/files/handlers/sfdc/sfdc_nagios.py
    - makedirs: True
    - mode: 755

notification_nagios_sfdc_config:
  file.managed:
    - name: {{ server.objects_cfg_dir }}/notify_sfdc.cfg
    - source: salt://nagios/files/handlers/sfdc/notify_sfdc.cfg
    - template: jinja
    - mode: 644
    - defaults:
      sfdc_params: {{ sfdc_params }}

notification_sfdc_plugin_config:
  file.managed:
    - name: {{ sfdc_params.sfdc_config_file }}
    - source: salt://nagios/files/handlers/sfdc/sfdc_nagios.yaml
    - template: jinja
    - mode: 644
    - defaults:
      sfdc_params: {{ sfdc_params }}

notification_sfdc_plugin_logrotate:
  file.managed:
    - name: /etc/logrotate.d/sfdc_nagios
    - source: salt://nagios/files/handlers/sfdc/sfdc_nagios_logrotate
    - template: jinja
    - mode: 644
    - defaults:
      sfdc_params: {{ sfdc_params }}
{%- endif %}

{%- if server.notification.slack is defined and server.notification.slack.get('enabled', false) %}
{%- set slack_params = {
    'log_file': server.log_dir + '/slack_nagios.log',
    'slack_plugin': server.handler_dir + '/slack/slack.py',
} %}
{%- do slack_params.update(server.notification.slack) %}
notification_slack_plugin_logrotate:
  file.managed:
    - name: /etc/logrotate.d/slack_nagios
    - source: salt://nagios/files/handlers/slack/slack_nagios_logrotate
    - template: jinja
    - mode: 644
    - defaults:
      slack_params: {{ slack_params }}

notification_nagios_slack_config:
  file.managed:
    - name: {{ server.objects_cfg_dir }}/notify_slack.cfg
    - source: salt://nagios/files/handlers/slack/notify_slack.cfg
    - template: jinja
    - mode: 644
    - defaults:
      slack_params: {{ slack_params }}

notification_slack_plugin:
  file.managed:
    - name: {{ slack_params.slack_plugin }}
    - source: salt://nagios/files/handlers/slack/slack.py
    - makedirs: true
    - mode: 755
{%- endif %}

{%- if server.notification.pagerduty is defined and server.notification.pagerduty.get('enabled', false) %}
{%- set pager_params = {
    'pager_plugin': server.handler_dir + '/pagerduty/pagerduty.pl',
} %}
{%- do pager_params.update(server.notification.pagerduty) %}
notification_nagios_pagerduty_config:
  file.managed:
    - name: {{ server.objects_cfg_dir }}/notify_pagerduty.cfg
    - source: salt://nagios/files/handlers/pagerduty/notify_pagerduty.cfg
    - template: jinja
    - mode: 644
    - defaults:
      pager_params: {{ pager_params }}

notification_pagerduty_plugin:
  file.managed:
    - name: {{ pager_params.pager_plugin }}
    - source: salt://nagios/files/handlers/pagerduty/pagerduty.pl
    - mode: 755
    - makedirs: true

notification_pagerduty_dependencies:
  pkg.latest:
    - pkgs:
      - libjson-perl
      - libwww-perl
{%- endif %}
{%- endif %}
