
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
          basic_auth:
            username: nagiosadmin
            password: secret

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
      objects:
        contactgroups:
          group1:
            contactgroup_name: MyGroup
        contacts:
          contact1:
            alias: 'root_at_localhost'
            contact_name: Me
            contactgroups:
                - MyGroup
            email: 'root@localhost'
            host_notifications_enabled: 1
            host_notification_period: 24x7
            host_notification_options: 'd,r'
            host_notification_commands: notify-host-by-smtp
            service_notifications_enabled: 1
            service_notification_period: 24x7
            service_notification_options: 'w,u,c,r'
            service_notification_commands: notify-service-by-smtp


Read more
=========

* https://www.nagios.org
