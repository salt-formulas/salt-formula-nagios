{%- from "nagios/map.jinja" import server with context %}
{%- if server.enabled %}
include:
- nagios.server

{% set grain_hostname = server.dynamic.get('grain_hostname', 'nodename') %}
{% set hostname_suffix = server.dynamic.get('hostname_suffix') %}

{%- set hostgroups = {} %}

{%- set static_hostgroups = server.objects.get('hostgroups', {}) %}
{% for hg_id, hg in static_hostgroups.items() %}
  {% if hg.get('members', False) %}
    {% if hg.members is string %}
      {% do hostgroups.update({hg.get('name', hg_id): [hg.members]})%}
    {% elif hg.members is iterable %}
      {% do hostgroups.update({hg.get('name', hg_id): hg.members})%}
    {% endif %}
  {% endif %}
{% endfor %}

{% if server.dynamic is mapping and server.dynamic.enabled %}
{% if server.dynamic.hostgroups is iterable and server.dynamic.hostgroups|length > 0 %}
{% for conf in server.dynamic.hostgroups %}
{% if conf.name not in hostgroups %}
  {% do hostgroups.update({conf.name: []}) %}
{% endif %}
{% for host_name, grains in salt['mine.get'](conf.get('target', '*'), 'grains.items', conf.get('expr_from', 'compound')).items() %}

{% if hostname_suffix %}
{% set full_host_name = grains[grain_hostname] + '.' + hostname_suffix %}
{% else %}
{% set full_host_name = grains[grain_hostname] %}
{% endif %}

{% if full_host_name  not in hostgroups[conf.name] %}
{% do hostgroups[conf.name].append(full_host_name) %}
{% endif%}
{% endfor %}
{% endfor %}
{% endif %}

{% if hostgroups.keys()|length > 0 %}
Nagios hostgroups configurations:
  file.managed:
    - name: {{ server.objects_cfg_dir }}/{{ server.objects_file_prefix }}.hostgroups.cfg
    - template: jinja
    - user: root
    - mode: 644
    - contents: |
{% for hg, hosts in hostgroups.items() %}
  {% if hosts|length > 0 %}
        define hostgroup {
          hostgroup_name {{ hg }}
          members {{ hosts|join(',') }}
        }
  {%- endif %}
{% endfor %}
{% endif %}

{# configure user definied hosts #}
{%- set hosts = server.objects.get('hosts', {}) %}

{% if server.dynamic.hosts is iterable and server.dynamic.hosts|length > 0 %}

{% set interface_names = {} %}
{% for conf in server.dynamic.hosts %}

{% for host_name, h_grains in salt['mine.get'](conf.get('target', '*'), 'grains.items', conf.get('expr_from', 'compound')).items() %}

{% if conf.get('network') %}

{% set address = salt['nagios_alarming.host_address'](conf.get('network'),
       h_grains[conf.get('ip_version', 'ipv4')]) %}

{% else %} {# legacy code #}
{% for nic in conf.get('interface', ['eth0']) %}
{% if h_grains['ip_interfaces'].get(nic, [])|length > 0%}
    {% if host_name not in interface_names %}
      {% do interface_names.update({host_name: []}) %}
    {% endif %}
    {% do interface_names[host_name].append(nic) %}
{% endif %}
{% endfor %}

{% if interface_names.get(host_name, [])|length > 0 %}
{% set address = h_grains['ip_interfaces'][interface_names[host_name][0]][0] %}
{% endif %}

{% endif %}

{% if address is defined and address %}

{% if hostname_suffix %}
{% set full_host_name = h_grains[grain_hostname] + '.' + hostname_suffix %}
{% else %}
{% set full_host_name = h_grains[grain_hostname] %}
{% endif %}

{% do salt['grains.filter_by']({'default': hosts},
  merge={
    h_grains[grain_hostname]: {
      'address': address,
      'host_name': full_host_name,
      'display_name': h_grains[grain_hostname],
    }
  })
%}

{% if conf.use is not defined and conf.get('register', 0) == 0 %}
{% do conf.update({'use': server.default_host_template}) %}
{% endif %}

{% do salt['grains.filter_by']({'default': hosts},
  merge={
    h_grains[grain_hostname]: conf,
  })
%}
{% endif %}
{% endfor %}
{% endfor %}

{% endif %}
{% endif %}
nagios host configurations:
  file.managed:
    - name: {{ server.objects_cfg_dir }}/{{ server.objects_file_prefix }}.hosts.cfg
    - source: salt://nagios/files/hosts.cfg
    - template: jinja
    - user: root
    - mode: 644
    - defaults:
      hosts: {{ hosts|yaml }}
{%- endif %}
