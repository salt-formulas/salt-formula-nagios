
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

Nagios UI configrations with HTTP basic authentication (use "readonly" flag to specify readonly users)

.. code-block:: yaml

    nagios:
      server:
        enabled: true
        ui:
          enabled: true
          auth:
            basic:
              # this is the main admin, it cannot have a 'readonly' flag.
              username: nagiosadmin
              password: secret
              # 'users' section is optional, allows defining additional users.
              users:
                - username: nagios_admin_2
                  password: secret2
                - username: nagios_user
                  password: secret3
                  readonly: true

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
          grain_interfaces: 'ip4_interfaces' # the default
          #hostname_suffix: .prod # optionally suffix hostnames
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
              network: 10.0.0.0/8
          services:
            - target: 'G@roles:openssh.server'
              name: SSH
              use: generic_service_tpl
              check_command: check_ssh
            - target: 'G@roles:nagios.server'
              name: HTTP Nagios
              use: generic_service_tpl
              check_command: check_http_basic_auth!localhost!${nagios:server:ui:port}


Note about dynamic hosts IP addresses configuration:

There are 2 different ways to configure the Host IP adddresses, the preferred way
is to define the **network** of the nodes to pickup the first IP address found
belonging to this network.

.. code-block:: yaml

    nagios:
      server:
        enabled: true
        dynamic:
          enabled: true
          hosts:
            - target: '*'
              contact_groups: Operator
              network: 10.0.0.0/8


The alternative way is to define the **interface** list, to pickup the first IP
address of the first interface found.

.. code-block:: yaml

    nagios:
      server:
        enabled: true
        dynamic:
          enabled: true
          hosts:
            - target: '*'
              contact_groups: Operator
              interface:
              - eth0
              - ens0

If both properties are defined, the **network** option wins and the **interface** is
ignored.


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


Nagios Notification Handlers
============================

You can configure notification handlers.  Currently supported handlers are SMTP, Slack,
Salesforce, and Pagerduty.

.. code-block:: yaml

    nagios:
      server:
        enabled: true
        notification:
          slack:
            enabled: true
            webhook_url: https://hooks.slack.com/services/abcdef/12345
          pagerduty:
            enabled: true
            key: abcdef12345
          sfdc:
            enabled: true
            client_id: abcdef12345
            client_secret: abcdef12345
            username: abcdef
            password: abcdef
            auth_url: https://abcedf.my.salesforce.com
            environment: abcdef
            organization_id: abcdef


.. code-block:: yaml

    # SMTP without auth
    nagios:
      server:
        enabled: true
        notification:
          smtp:
            auth: false
            url: smtp://127.0.0.1:25
            from: nagios@localhost
            # Notification email subject can be defined, must be one line
            # default subjects are:
            host_subject: >-
               ** $NOTIFICATIONTYPE$ Host Alert: $HOSTNAME$ is $HOSTSTATE$ **
            service_subject: >-
               ** $NOTIFICATIONTYPE$ Service Alert: $HOSTNAME$/$SERVICEDESC$ is $SERVICESTATE$ **

    # An example using a Gmail account as a SMTP relay
    nagios:
      server:
        enabled: true
        notification:
          smtp:
            auth: login
            url: smtp://smtp.gmail.com:587
            from: <you>@gmail.com
            starttls: true
            username: foo
            password: secret


Each handler adds two commands, `notify-host-by-<HANDLER>`, and `notify-service-by-<HANDLER>`, that you can
reference in a contact.

.. code-block:: yaml

    nagios:
      server:
        objects:
          contact:
            sfdc:
              alias: sfdc
              contactgroups:
                - Operator
              email: root@localhost
              host_notification_commands: notify-host-by-sfdc
              host_notification_options: d,r
              host_notification_period: 24x7
              host_notifications_enabled: 1
              service_notification_commands: notify-service-by-sfdc
              service_notification_options: c,r
              service_notification_period: 24x7
              service_notifications_enabled: 1


By default in Stacklight, notifications are only enabled for `00-top-clusters` and individual host
and SSH checks.  If you want to enable notifications for all checks you can enable this value:

.. code-block:: yaml

    nagios:
      server:
        enabled: true
        notification:
          alarm_enabled_override: true


The notification interval defaults to zero, which will only send one notification when the alert
triggers.  You can override the interval if you want notifications to repeat.  For example, to
have them repeat every 30 minutes:

.. code-block:: yaml

    nagios:
      server:
        enabled: true
        objects:
          hosts:
            generic_host_tpl:
              notification_interval: 30
          services:
            generic_service_tpl:
              notification_interval: 30


Read more
=========

* https://www.nagios.org

Platform support
================

This formula has been tested on Ubuntu Xenial **only**.

TODO
====

* Configure Apache using salt-formula-apache (using service metadata) or alternatively
  using Nginx.

Documentation and Bugs
======================

To learn how to install and update salt-formulas, consult the documentation
available online at:

    http://salt-formulas.readthedocs.io/

In the unfortunate event that bugs are discovered, they should be reported to
the appropriate issue tracker. Use Github issue tracker for specific salt
formula:

    https://github.com/salt-formulas/salt-formula-nagios/issues

For feature requests, bug reports or blueprints affecting entire ecosystem,
use Launchpad salt-formulas project:

    https://launchpad.net/salt-formulas

You can also join salt-formulas-users team and subscribe to mailing list:

    https://launchpad.net/~salt-formulas-users

Developers wishing to work on the salt-formulas projects should always base
their work on master branch and submit pull request against specific formula.

    https://github.com/salt-formulas/salt-formula-nagios

Any questions or feedback is always welcome so feel free to join our IRC
channel:

    #salt-formulas @ irc.freenode.net
