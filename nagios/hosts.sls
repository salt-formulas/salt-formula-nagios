{%- from "nagios/map.jinja" import server with context %}
{%- if server.enabled %}

{%- set hostgroups = {} %} {# = server.objects.get('hostgroups', {}) %}#}

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
{% if server.dynamic.hostgroups is mapping and server.dynamic.hostgroups.items()|length > 0 %}
{% for dyn_host, conf in server.dynamic.hostgroups.items() %}
{% if dyn_host not in hostgroups %}
  {% do hostgroups.update({conf.get('name', dyn_host): []}) %}
{% endif %}
{% for host_name, grains in salt['mine.get'](conf.get('grain_match', '*'), 'grains.items', conf.get('expr_from', 'compound')).items() %}
{% do hostgroups[conf.get('name', dyn_host)].append(grains['nodename']) %}
{% endfor %}
{% endfor %}
{% endif %}

{% if hostgroups.keys()|length > 0 %}
Nagios hostgroups confiugrations:
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

{% if server.dynamic.hosts is mapping and server.dynamic.hosts.items()|length > 0 %}

{% for dyn_host, conf in server.dynamic.hosts.items() %}

{%- for host_name, grains in salt['mine.get']('*', 'grains.items').items() %}

{% set interface_name = [] %}

{% for nic in conf.get('interface', ['eth0']) %}
{% if nic in grains['ip_interfaces'] %}
    {% do interface_name.append(nic) %}
{% endif %}
{% endfor %}

{% do hosts.update({
  grains['nodename']: {
    'host_name': grains['nodename'],
    'address': grains['ip_interfaces'][interface_name[0]][0],
    'contact_groups': conf.get('contact_groups', None),
    'use': conf.get('use', server.default_host_template),
  }
}
)
%}
{{ dyn_host }} {{ host_name }} foo debug:
  file.managed:
    - name: /tmp/debug.{{ dyn_host}}.{{host_name}}
    - template: jinja
    - user: root
    - mode: 644
    - contents: |
        {{ conf }}
        {{ grains['nodename'] }}
        {{ grains['ip_interfaces'] }}
        {{ host_name }}

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
