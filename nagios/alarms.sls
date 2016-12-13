{%- from "nagios/map.jinja" import server with context %}
{%- if server.enabled %}
include:
- nagios.server
{% if server.dynamic.stacklight_alarms is mapping and server.dynamic.stacklight_alarms.enabled is defined and server.dynamic.stacklight_alarms.enabled %}

{% set grain_hostname = server.dynamic.get('grain_hostname', 'nodename') %}
{% set hostname_suffix = server.dynamic.get('hostname_suffix') %}

{% set alarms = {} %}
{% set commands = {} %}
{%- for node_name, node_grains in salt['mine.get']('*', 'grains.items').items() %}

{%- if node_grains.heka is defined and node_grains.heka.metric_collector is mapping %}

{% set triggers = node_grains.heka.metric_collector.get('trigger', {}) %}
{% for alarm_id, alarm_def in node_grains.heka.metric_collector.get('alarm', {}).items() %}
{% if alarm_def.get('alerting', 'enabled') != 'disabled' %}

{% set check_command = 'check_dummy_unknown_' + node_grains[grain_hostname] + alarm_id %}
{% set threshold = salt['nagios_alarming.threshold'](alarm_def, triggers) %}

{% do commands.update({check_command: { 'command_line': 'check_dummy 3 "No data received for at least {} seconds"'.format(threshold)}}) %}

{% if hostname_suffix %}
{% set full_host_name = node_grains[grain_hostname] + '.' + hostname_suffix %}
{% else %}
{% set full_host_name = node_grains[grain_hostname] %}
{% endif %}

{% do alarms.update(salt['nagios_alarming.alarm_to_service'](
                     full_host_name,
                     alarm_id,
                     alarm_def,
                     check_command,
                     threshold,
                     {'use': server.dynamic.stacklight_alarms.get('service_template', server.default_service_template)})) %}
{% endif %}
{% endfor %}
{%- endif %} {# end metric_collector alarms #}

{% endfor %}

nagios alarm service configurations:
  file.managed:
    - name: {{ server.objects_cfg_dir }}/{{ server.objects_file_prefix }}.alarms.cfg
    - source: salt://nagios/files/services.cfg
    - template: jinja
    - user: root
    - mode: 644
    - defaults:
      services: {{ alarms|yaml }}

{% if commands.keys()|length > 0 %}
Nagios alarm dummy commands configurations:
  file.managed:
    - name: {{ server.objects_cfg_dir }}/{{ server.objects_file_prefix }}.alarms-commands.cfg
    - template: jinja
    - source: salt://nagios/files/commands.cfg
    - user: root
    - mode: 644
    - defaults:
      commands: {{ commands|yaml }}
{% endif %}
{% else %}
nagios alarm service configurations purge:
  file.absent:
    - name: {{ server.objects_cfg_dir }}/{{ server.objects_file_prefix }}.alarms.cfg

Nagios alarm dummy commands configurations purge:
  file.absent:
    - name: {{ server.objects_cfg_dir }}/{{ server.objects_file_prefix }}.alarms-commands.cfg
{% endif %}
{% endif %}
