{%- if pillar.nagios is defined %}
include:
{%- if pillar.nagios.server is defined and pillar.nagios.server.enabled %}
- nagios.server
- nagios.contactgroups
- nagios.contacts
- nagios.hosts
- nagios.commands
- nagios.services
- nagios.alarms
- nagios.alarm_clusters
{%- endif %}
{%- endif %}
