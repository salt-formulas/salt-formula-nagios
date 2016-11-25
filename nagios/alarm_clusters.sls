{%- from "nagios/map.jinja" import server with context %}
{%- if server.enabled %}
include:
- nagios.server
{% if server.dynamic.stacklight_alarm_clusters is mapping and server.dynamic.stacklight_alarm_clusters.enabled is defined and server.dynamic.stacklight_alarm_clusters.enabled %}

{% set alarms = {} %}
{% set commands = {} %}
{% set hosts = {} %}

{% set default_host =  server.dynamic.stacklight_alarm_clusters.get('default_host', '00-others') %}

{% set check_command = 'check_dummy_unknown_for_stacklight_clusters' %}
{% set threshold = 60 %}

{% do commands.update({check_command: { 'command_line': 'check_dummy 3 "No data received for at least {} seconds"'.format(threshold)}}) %}
{% do commands.update({'dummy_ok_for_cluster_hosts': { 'command_line': 'check_dummy 0 "OK"'}}) %}

{% set dimension_key = server.dynamic.stacklight_alarm_clusters.get('dimension_key') %}

{%- for node_name, node_grains in salt['mine.get']('*', 'grains.items').iteritems() %}
{%- if node_grains.heka is defined and node_grains.heka.aggregator is mapping %}

{% for alarm_id, alarm_def in node_grains.heka.aggregator.get('alarm_cluster', {}).items() %}
{% if alarm_def.get('alerting', 'enabled_with_notification') != 'disabled' %}
{% set host_name = salt['nagios_alarming.alarm_cluster_hostname'](
                    dimension_key,
                    alarm_def,
                    default_host)
%}

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
    {%- if server.automatic_starting %}
    - watch_in:
      - service: {{ server.service }}
    {%- endif %}

Nagios alarm cluster service configurations:
  file.managed:
    - name: {{ server.objects_cfg_dir }}/{{ server.objects_file_prefix }}.alarm_clusters.cfg
    - source: salt://nagios/files/services.cfg
    - template: jinja
    - user: root
    - mode: 644
    - defaults:
      services: {{ alarms|yaml }}
    {%- if server.automatic_starting %}
    - watch_in:
      - service: {{ server.service }}
    {%- endif %}

Nagios cluster host configurations:
  file.managed:
    - name: {{ server.objects_cfg_dir }}/{{ server.objects_file_prefix }}.cluster_hosts.cfg
    - source: salt://nagios/files/hosts.cfg
    - template: jinja
    - user: root
    - mode: 644
    - defaults:
      hosts: {{ hosts|yaml }}
    {%- if server.automatic_starting %}
    - watch_in:
      - service: {{ server.service }}
    {%- endif %}

{% else %}
Nagios alarm cluster dummy commands configurations:
  file.absent:
    - name: {{ server.objects_cfg_dir }}/{{ server.objects_file_prefix }}.alarm_clusters-commands.cfg
    {%- if server.automatic_starting %}
    - watch_in:
      - service: {{ server.service }}
    {%- endif %}

Nagios alarm cluster service configurations:
  file.absent:
    - name: {{ server.objects_cfg_dir }}/{{ server.objects_file_prefix }}.alarm_clusters.cfg
    {%- if server.automatic_starting %}
    - watch_in:
      - service: {{ server.service }}
    {%- endif %}

Nagios cluster host configurations:
  file.absent:
    - name: {{ server.objects_cfg_dir }}/{{ server.objects_file_prefix }}.cluster_hosts.cfg
    {%- if server.automatic_starting %}
    - watch_in:
      - service: {{ server.service }}
    {%- endif %}
{% endif %}
{% endif %}

