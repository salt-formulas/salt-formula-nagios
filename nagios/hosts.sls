{%- from "nagios/map.jinja" import server with context %}
{%- if server.enabled %}

{% set grain_hostname = server.dynamic.get('grain_hostname', 'nodename') %}

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
{% for host_name, grains in salt['mine.get'](conf.get('grain_match', '*'), 'grains.items', conf.get('expr_from', 'compound')).items() %}
{% do hostgroups[conf.name].append(grains[grain_hostname]) %}
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
        define hostgroup {
          hostgroup_name {{ hg }}
          members {{ hosts|join(',') }}
        }
{% endfor %}
    - watch_in:
      - service: {{ server.service }}
{% endif %}

{# configure user definied hosts #}
{%- set hosts = server.objects.get('hosts', {}) %}

{% if server.dynamic.hosts is iterable and server.dynamic.hosts|length > 0 %}

{% for conf in server.dynamic.hosts %}

{% for host_name, grains in salt['mine.get'](conf.get('grain_match', '*'), 'grains.items', conf.get('expr_from', 'compound')).items() %}

{% set interface_name = [] %}

{% for nic in conf.get('interface', ['eth0']) %}
{% if nic in grains['ip_interfaces'] %}
    {% do interface_name.append(nic) %}
{% endif %}
{% endfor %}

{% if interface_name|length > 0 %}
{% do hosts.update({
  grains[grain_hostname]: {
    'host_name': grains[grain_hostname],
    'address': grains['ip_interfaces'][interface_name[0]][0],
    'contact_groups': conf.get('contact_groups', None),
    'use': conf.get('use', server.default_host_template),
  }
}
)
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
      hosts: {{ hosts }}
    - watch_in:
      - service: {{ server.service }}
{%- endif %}
