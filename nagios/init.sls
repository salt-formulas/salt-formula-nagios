{%- if pillar.nagios is defined %}
include:
{%- if pillar.nagios.server is defined %}
- nagios.server
- nagios.contactgroups
- nagios.contacts
{%- endif %}
{%- endif %}
