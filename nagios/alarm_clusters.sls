{%- from "nagios/map.jinja" import server with context %}
{%- if server.enabled %}
include:
- nagios.server
{% if server.dynamic.stacklight_alarm_clusters is mapping and server.dynamic.stacklight_alarm_clusters.enabled is defined and server.dynamic.stacklight_alarm_clusters.enabled %}

{% set grain_hostname = server.dynamic.get('grain_hostname', 'nodename') %}
{% set alarms = {} %}
{% set commands = {} %}
{% set hosts = {} %}

{% set default_host_alarm_clusters =  grains.get('heka', {}).get('aggregator', {}).get('nagios_host_alarm_clusters', '00-clusters') %}

{% set check_command = 'check_dummy_unknown_for_stacklight_clusters' %}
{% set threshold = 60 %}

{% do commands.update({check_command: { 'command_line': 'check_dummy 3 "No data received for at least {} seconds"'.format(threshold)}}) %}
{% do commands.update({'dummy_ok_for_cluster_hosts': { 'command_line': 'check_dummy 0 "OK"'}}) %}


{%- for node_name, node_grains in salt['mine.get']('*', 'grains.items').iteritems() %}
{%- if node_grains.heka is defined and node_grains.heka.aggregator is mapping %}

{% for alarm_id, alarm_def in node_grains.heka.aggregator.get('alarm_cluster', {}).items() %}
{% if alarm_def.get('alerting', 'enabled_with_notification') != 'disabled' %}
{% set host_name = alarm_def.host_name|default(default_host_alarm_clusters) %}

{% do salt['grains.filter_by']({'default': hosts},
  merge={ host_name: {
   'address': '1.1.1.1',
   'host_name': host_name,
   'check_command': 'dummy_ok_for_cluster_hosts',
   'use': server.dynamic.stacklight_alarm_clusters.get('host_template', server.default_host_template),
  }
  })
%}

{% do alarms.update(salt['nagios_alarming.alarm_cluster_to_service'](
                     host_name,
                     alarm_id,
                     alarm_def,
                     check_command,
                     threshold,
                     {'use': server.dynamic.stacklight_alarm_clusters.get('service_template', server.default_service_template)})) %}
{% endif %}
{%- endfor %}

{%- endif %}
{%- endfor %}

Nagios alarm cluster dummy commands configurations:
  file.managed:
    - name: {{ server.objects_cfg_dir }}/{{ server.objects_file_prefix }}.alarm_clusters-commands.cfg
    - template: jinja
    - source: salt://nagios/files/commands.cfg
    - user: root
    - mode: 644
    - defaults:
      commands: {{ commands|yaml }}
    - watch_in:
      - service: {{ server.service }}

Nagios alarm cluster service configurations:
  file.managed:
    - name: {{ server.objects_cfg_dir }}/{{ server.objects_file_prefix }}.alarm_clusters.cfg
    - source: salt://nagios/files/services.cfg
    - template: jinja
    - user: root
    - mode: 644
    - defaults:
      services: {{ alarms|yaml }}
    - watch_in:
      - service: {{ server.service }}

Nagios cluster host configurations:
  file.managed:
    - name: {{ server.objects_cfg_dir }}/{{ server.objects_file_prefix }}.cluster_hosts.cfg
    - source: salt://nagios/files/hosts.cfg
    - template: jinja
    - user: root
    - mode: 644
    - defaults:
      hosts: {{ hosts|yaml }}
    - watch_in:
      - service: {{ server.service }}

{% else %}
Nagios alarm cluster dummy commands configurations:
  file.absent:
    - name: {{ server.objects_cfg_dir }}/{{ server.objects_file_prefix }}.alarm_clusters-commands.cfg
    - watch_in:
      - service: {{ server.service }}

Nagios alarm cluster service configurations:
  file.absent:
    - name: {{ server.objects_cfg_dir }}/{{ server.objects_file_prefix }}.alarm_clusters.cfg
    - watch_in:
      - service: {{ server.service }}

Nagios cluster host configurations:
  file.absent:
    - name: {{ server.objects_cfg_dir }}/{{ server.objects_file_prefix }}.cluster_hosts.cfg
    - watch_in:
      - service: {{ server.service }}
{% endif %}
{% endif %}

