
======
nagios
======

Salt formula to set up and manage nagios

Available states
================

``nagios.server``

Set up Nagios server


Sample pillars
==============

Single nagios service

.. code-block:: yaml

    nagios:
      server:
        enabled: true

All Nagios configurations can be configured

.. code-block:: yaml

    nagios:
      server:
        enabled: true
        accept_passive_service_checks: 1
        process_performance_data: 0
        check_service_freshness: 1
        check_host_freshness: 0

Nagios UI configrations with HTTP basic authentication

.. code-block:: yaml

    nagios:
      server:
        enabled: true
        ui:
          enabled: true
          auth:
            basic:
              username: nagiosadmin
              password: secret

Nagios UI configuration with LDAP authentication/authorization:


.. code-block:: yaml

    nagios:
      server:
        enabled: true
        ui:
          enabled: true
          auth:
            basic:
              username: nagiosadmin
              password: secret
            ldap:
              enabled: true
              # Url format is described here
              # http://httpd.apache.org/docs/2.0/mod/mod_auth_ldap.html#authldapurl
              url: ldaps://ldap.domain.ltd:<port>/cn=users,dc=domain,dc=local?uid?sub?<filter>
              bind_dn: cn=admin,dc=domain,dc=local
              bind_password: secret
              # Optionaly, restrict access to members of a group:
              ldap_group_dn: cn=admins,ou=groups,dc=domain,dc=local
              ldap_group_attribute: memberUid

The formula configures commands to send notifications by SMTP.
The authentifcation is disabled by default.
Authentication methods supported is either 'plain', 'login' or 'CRAMMD5'.

The command created `notify-service-by-smtp` and `notify-host-by-smtp` can be
referenced in the `contact` objects.

.. code-block:: yaml

    nagios:
      server:
        enabled: true
      notification:
        smtp:
          auth: false
          host: 127.0.0.1
          from: nagios@localhost
          username: foo
          password: secret

Nagios objects can be defined in pillar:

.. code-block:: yaml

    nagios:
      server:
        enabled: true
        objects:
          contactgroups:
            group1:
              contactgroup_name: Operator
          contacts:
            contact1:
              alias: 'root_at_localhost'
              contact_name: Me
              contactgroups:
                  - Operator
              email: 'root@localhost'
              host_notifications_enabled: 1
              host_notification_period: 24x7
              host_notification_options: 'd,r'
              host_notification_commands: notify-host-by-smtp
              service_notifications_enabled: 1
              service_notification_period: 24x7
              service_notification_options: 'w,u,c,r'
              service_notification_commands: notify-service-by-smtp
          commands:
            check_http_basic_auth:
              command_line: "check_http -4 -I '$ARG1$' -w 2 -c 3 -t 5 -p $ARG2$ -u '/' -e '401 Unauthorized'"

          services:
            generic_service_tpl:
              register: 0
              contact_groups: Operator
              process_perf_data: 0
              max_check_attempts: 3
          hosts:
            generic_host_tpl:
              notifications_enabled: 1
              event_handler_enabled: 1
              flap_detection_enabled: 1
              failure_prediction_enabled: 1
              process_perf_data: 0
              retain_status_information: 1
              retain_nonstatus_information: 1
              max_check_attempts: 10
              notification_interval: 0
              notification_period: 24x7
              notification_options: d,u,r
              contact_groups: Operator
              register: 0

Also, **hostgroups**, **hosts** and **services** can be created dynamically using
**mine**:

.. code-block:: yaml

    nagios:
      server:
        enabled: true
        dynamic:
          enabled: true
          grain_hostname: 'host'
          hostgroups:
            - target: '*'
              name: All
              expr_from: glob
            - target: 'G@roles:nova.controller'
              expr_from: compound # the default
              name: Nova Controller
            - target: 'G@roles:nova.compute'
              name: Nova Compute
            - target: 'G@roles:keystone.server'
              name: Keystone server
            - target: 'G@roles:influxdb.server'
              name: InfluxDB server
            - target: 'G@roles:elasticsearch.server'
              name: Elasticsearchserver
          hosts:
            - target: 'G@services:openssh'
              contact_groups: Operator
              use: generic_host_tpl
              interface:
              - eth0
              - ens3
          services:
            - target: 'G@roles:openssh.server'
              name: SSH
              use: generic_service_tpl
              check_command: check_ssh
            - target: 'G@roles:nagios.server'
              name: HTTP Nagios
              use: generic_service_tpl
              check_command: check_http_basic_auth!localhost!${nagios:server:ui:port}

StackLight Alarms
=================

StackLight alarms are configured dynamically using **mine** data which are exposed by the Heka
formula, respectively ``heka:metric_collector:alarm`` and ``heka:aggergator:alarm_cluster``.


To configure StackLight alarms per nodes (known as AFD):


.. code-block:: yaml

    nagios:
      server:
        enabled: true
      dynamic:
        enabled: true
        hosts:
          - target: 'G@services:openssh'
            contact_groups: Operator
            use: generic_host_tpl
            interface:
            - eth0
            - ens3
        stacklight_alarms:
          enabled: true
          service_template: generic_service_tpl # optional


To configure StackLight alarm clusters (known as GSE):


.. code-block:: yaml

    nagios:
      server:
        enabled: true
      dynamic:
        enabled: true
        stacklight_alarm_clusters:
          enabled: true
          service_template: generic_service_tpl # optional
          host_template: generic_host_tpl # optional
          dimension_key: nagios_host # optional
          default_host: clusters # optional


Read more
=========

* https://www.nagios.org

Plateforme support
=================

This formula has been tested on Ubuntu Xenial **only**.

TODO
====

* Find a more suitable way to configure IP address for **dynamic hosts** creation.
  Currently, a list of `NIC interfaces` is provided and the state picks the first
  IP address of the first interface found.
  This is to support different Linux kernel versions which use different interface names.
* Configure Apache using salt-formula-apache (using service metadata) or alternatively
  using Nginx.
